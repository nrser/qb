#!/usr/bin/python
#
# Copyright 2016 Red Hat | Ansible
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)


# Imports
# ============================================================================

from __future__ import absolute_import, division, print_function
__metaclass__ = type

import os
import re
import json
import logging

from ansible.module_utils.docker_common import (
    HAS_DOCKER_PY_2,
    AnsibleDockerClient,
    DockerBaseClass
)

from ansible.module_utils._text import to_native

try:
    if HAS_DOCKER_PY_2:
        from docker.auth import resolve_repository_name
    else:
        from docker.auth.auth import resolve_repository_name
    from docker.utils.utils import parse_repository_tag
except ImportError:
    # missing docker-py handled in docker_common
    pass


import qb.ipc.stdio
import qb.ipc.stdio.logging


# Globals
# ============================================================================

logger = qb.ipc.stdio.logging.getLogger('qb_docker_image')


# Casses
# ============================================================================

class ImageManager(DockerBaseClass):
    '''
    Adaptation and extension of the `ImageManager` class from Ansible's
    `docker_image` module for QB's `qb_docker_image` module.
    '''
    
    # Construction
    # ========================================================================

    def __init__(self, client, results):

        super(ImageManager, self).__init__()

        self.client = client
        self.results = results
        parameters = self.client.module.params
        self.check_mode = self.client.check_mode

        self.archive_path = parameters.get('archive_path')
        self.container_limits = parameters.get('container_limits')
        self.dockerfile = parameters.get('dockerfile')
        self.force = parameters.get('force')
        self.load_path = parameters.get('load_path')
        self.name = parameters.get('name')
        self.nocache = parameters.get('nocache')
        self.path = parameters.get('path')
        self.pull = parameters.get('pull')
        self.repository = parameters.get('repository')
        self.rm = parameters.get('rm')
        self.state = parameters.get('state')
        self.tag = parameters.get('tag')
        self.http_timeout = parameters.get('http_timeout')
        self.push = parameters.get('push')
        self.buildargs = parameters.get('buildargs')
        
        # QB additions
        self.try_to_pull = parameters.get('try_to_pull')
        
        self.logger = qb.ipc.stdio.logging.getLogger(
            'qb_docker_image:ImageManager',
        )

        # If name contains a tag, it takes precedence over tag parameter.
        repo, repo_tag = parse_repository_tag(self.name)
        if repo_tag:
            self.name = repo
            self.tag = repo_tag

        if self.state in ['present', 'build']:
            self.present()
        elif self.state == 'absent':
            self.absent()
        
    # END __init__
    
    
    # Instance Methods
    # ========================================================================
    
    # Helpers
    # ------------------------------------------------------------------------
    
    def out(self, msg):
        '''
        Just proxies to :attr:`client.out`, which writes to the master QB
        process' STDOUT (if available).
        
        :param msg: String or dict with output, but should usually be a
                    dict with Docker API/daemon output in this case; log
                    messages using the :attr:`logger`.
        
        :return:    None
        '''
        self.client.out(msg)
        
    
    def warn(self, warning, **values):
        '''
        Append a warning message to the `warnings` array of :attr:`results`
        that will be returned to Ansible and log it as a warning.
        '''
        warning = str(warning)
        self.results['warnings'].append(warning.format(**values))
        self.logger.warning(warning, payload=values)
    
    
    def fail(self, msg, **values):
        '''
        Proxy to :attr:`client.fail`.
        '''
        self.client.fail(msg, **values)
    
    
    def append_action(self, msg, **values):
        '''
        Add a message to the `actions` array in :attr:`results` and log it
        (as `info`).
        
        I'm not sure what 'actions' are for, but they were here when I adapted
        it... maybe something to do with "check mode"?
        '''
        
        formatted = msg.format(**values)
        self.logger.info(formatted, payload=values)
        self.results['actions'].append(formatted)
        
    
    def image_summary(self, image):
        return dict(
            Id          = image['Id'],
            RepoTags    = image['RepoTags'],
            Created     = image['Created'],
            Metadata    = image['Metadata'],
        )
    
    
    # States
    # ------------------------------------------------------------------------

    def present(self):
        '''
        Handles state = 'present', which includes building, loading or pulling
        an image, depending on user provided parameters.

        :return:    None
        '''
        
        self.logger.debug(
            "Starting state `present`...",
            payload = dict(
                name    = self.name,
                tag     = self.tag,
            )
        )
        
        existing_image = self.client.find_image(name=self.name, tag=self.tag)
        
        if existing_image:
            self.logger.info(
                "Found existing image `{find_name}` in local daemon",
                payload = dict(
                    find_name   = "{}:{}".format(self.name, self.tag),
                    **self.image_summary(existing_image)
                )
            )
        
        # Keep track of what images we get from where
        pulled_image = None
        built_image = None
        loaded_image = None
        
        if not existing_image or self.force:
            # Try to pull if we're not forcing (which means we want to
            # re-build/load regardless) and `self.try_to_pull` is `True`
            if not self.force and self.try_to_pull:
                self.append_action(
                    'Tried to pull image `{name}:{tag}`',
                    name    = self.name,
                    tag     = self.tag
                )
                
                self.results['changed'] = True
                
                if not self.check_mode:
                    pulled_image = self.client.try_pull_image(
                        self.name,
                        tag=self.tag
                    )
                    
                    if pulled_image:
                        self.append_action(
                            'Pulled image `{name}:{tag}`',
                            name    = self.name,
                            tag     = self.tag
                        )
                        self.results['image'] = pulled_image
            # END if not self.force and self.try_to_pull:
            
            if pulled_image is None:
                if self.path:
                    # Build the image
                    if not os.path.isdir(self.path):
                        self.fail(
                            "Requested build path `{path}` could not be " +
                            "found or you do not have access.",
                            path    = self.path,
                        )
                        
                    image_name = self.name
                    if self.tag:
                        image_name = "%s:%s" % (self.name, self.tag)
                    
                    self.logger.info(
                        "Building image `{image_name}`",
                        payload = dict(
                            image_name  = image_name,
                        )
                    )
                    
                    self.append_action(
                        "Built image `{image_name}` from `{path}`",
                        image_name  = image_name,
                        path        = self.path,
                    )
                    
                    self.results['changed'] = True
                    
                    if not self.check_mode:
                        built_image = self.build_image()
                        self.results['image'] = built_image
                        
                elif self.load_path:
                    
                    # Load the image from an archive
                    if not os.path.isfile(self.load_path):
                        self.fail(
                            "Error loading image `{name}`. " +
                            "Specified load path `{load_path}` does not exist.",
                            name        = self.name,
                            load_path   = self.load_path,
                        )
                        
                    image_name = self.name
                    
                    if self.tag:
                        image_name = "%s:%s" % (self.name, self.tag)
                    
                    self.append_action(
                        "Loaded image `{image_name}` from `{load_path}`",
                        image_name  = image_name,
                        load_path   = self.load_path,
                    )
                    
                    self.results['changed'] = True
                    
                    if not self.check_mode:
                        loaded_image = self.load_image()
                        self.results['image'] = loaded_image
                        
                else:
                    # pull the image
                    self.append_action(
                        'Pulled image `{name}:{tag}`',
                        name    = self.name,
                        tag     = self.tag,
                    )
                    
                    self.results['changed'] = True
                    
                    if not self.check_mode:
                        pulled_image = self.client.pull_image(
                            self.name,
                            tag = self.tag,
                        )
                        
                        self.results['image'] = pulled_image
                        
                        if (
                            existing_image and
                            existing_image == self.results['image']
                        ):
                            self.results['changed'] = False
            # END if pulled_image is None:
        # END if not image or self.force:
        
        # Archive the image if we have an archive path
        if self.archive_path:
            self.archive_image(self.name, self.tag)
        
        # Tag the image to a repository if we have one
        if self.repository:
            self.tag_image(
                self.name,
                self.tag,
                self.repository,
                force   = self.force,
                push    = self.push,
            )
        
        # This is weird to me logically, but I'm attempting to stick to the
        # Ansible `docker_image` module behavior...
        # 
        # We only push to the default repository (Docker Hub) if we didn't
        # receive a `self.respository`. I guess this is for when you're using
        # another repo than Docker Hub that you provide as `repository` and
        # then it assumes you would never want to push to Docker Hub *too*.
        # 
        # OK, that kinda makes sense to me...
        # 
        elif self.push:
            if pulled_image is not None:
                # Regadless of anything, we never want to push an image we
                # just pulled... makes no sense.
                self.logger.debug(
                    "Image was pulled from repo, not pushing",
                    payload=self.image_summary(pulled_image)
                )
            
            else:
                # Ok, now we can look at pushing...
                if self.force:
                    # We're forcing, so force the push
                    self.logger.info(
                        "FORCING push of image `{name}:{tag}`...",
                        payload = dict(
                            name    = self.name,
                            tag     = self.tag,
                        )
                    )
                    self.push_image(self.name, self.tag)
                
                else:
                    # We only want to push if we built or loaded an image
                    if built_image is not None:
                        self.logger.info(
                            "Pushing built image `{name}:{tag}`",
                            payload = dict(
                                name    = self.name,
                                tag     = self.tag,
                                **self.image_summary(built_image)
                            )
                        )
                        self.push_image(self.name, self.tag)
                        
                    elif loaded_image is not None:
                        self.logger.info(
                            "Pushing loaded image `{name}:{tag}`",
                            payload = dict(
                                name    = self.name,
                                tag     = self.tag,
                                **self.image_summary(loaded_image)
                            )
                        )
                        self.push_image(self.name, self.tag)
                    
                    else:
                        self.logger.info(
                            "No image built or loaded, not pushing"
                        )
                        
                # END if self.force / else
            # END if pulled_image is not None / else
        # END if self.repository / elif self.push
        
        # QB addition - set the existing image as the result. Not sure why
        # the Ansible version doesn't do this..?
        if not self.results['image'] and existing_image is not None:
            self.results['image'] = existing_image
        
        self.logger.debug(
            "State `present` done",
            payload = dict(
                results = self.results,
            )
        )
    # END present()
    
    
    def absent(self):
        '''
        Handles state = 'absent', which removes an image.

        :return None
        '''
        image = self.client.find_image(self.name, self.tag)
        if image:
            name = self.name
            if self.tag:
                name = "%s:%s" % (self.name, self.tag)
            if not self.check_mode:
                try:
                    self.client.remove_image(name, force=self.force)
                except Exception as exc:
                    self.fail("Error removing image %s - %s" % (name, str(exc)))

            self.results['changed'] = True
            self.append_action(
                "Removed image `{name}`",
                name = name,
            )
            self.results['image']['state'] = 'Deleted'
    
    
    # Actions
    # ------------------------------------------------------------------------
    
    def archive_image(self, name, tag):
        '''
        Archive an image to a .tar file. Called when archive_path is passed.

        :param name - name of the image. Type: str
        :return None
        '''

        if not tag:
            tag = "latest"

        image = self.client.find_image(name=name, tag=tag)
        if not image:
            self.logger.info(
                "archive image: image {name}:{tag} not found",
                payload = dict(
                    name    = name,
                    tag     = tag,
                )
            )
            return

        image_name = "%s:%s" % (name, tag)
        
        self.append_action(
            'Archived image `{image_name}` to `{archive_path}`',
            image_name      = image_name,
            archive_path    = self.archive_path
        )
        
        self.results['changed'] = True
        
        if not self.check_mode:
            
            self.logger.info(
                "Getting archive of image `{image_name}`",
                payload = dict(
                    image_name  = image_name
                )
            )
            
            try:
                image = self.client.get_image(image_name)
            except Exception as exc:
                self.fail(
                    "Error getting image `%s` - %s" % (image_name, str(exc))
                )

            try:
                with open(self.archive_path, 'w') as fd:
                    for chunk in image.stream(2048, decode_content=False):
                        fd.write(chunk)
            except Exception as exc:
                self.fail(
                    "Error writing image archive `%s` - %s" % (
                        self.archive_path,
                        str(exc)
                    )
                )

        image = self.client.find_image(name=name, tag=tag)
        if image:
            self.results['image'] = image
    
    
    def push_image(self, name, tag=None):
        '''
        If the name of the image contains a repository path, then push the image.

        :param name Name of the image to push.
        :param tag Use a specific tag.
        :return: None
        '''
        
        repository = name
        if not tag:
            repository, tag = parse_repository_tag(name)
        registry, repo_name = resolve_repository_name(repository)

        self.logger.info(
            "push `{name}` to `{registry}/{repo_name}:{tag}`",
            payload = dict(
                name        = self.name,
                registry    = registry,
                repo_name   = repo_name,
                tag         = tag
            )
        )

        if registry:
            
            self.append_action(
                "Pushed image `{name}` to `{registry}/{repo_name}:{tag}`",
                name        = self.name,
                registry    = registry,
                repo_name   = repo_name,
                tag         = tag
            )
            
            self.results['changed'] = True
            
            if not self.check_mode:
                status = None
                try:
                    for line in self.client.push(
                        repository,
                        tag     = tag,
                        stream  = True,
                        decode  = True
                    ):
                        self.out(line)
                        
                        if line.get('errorDetail'):
                            raise Exception(line['errorDetail']['message'])
                            
                        status = line.get('status')
                        
                except Exception as exc:
                    if re.search('unauthorized', str(exc)):
                        if re.search('authentication required', str(exc)):
                            self.fail(
                                "Error pushing image %s/%s:%s - %s. Try logging into %s first." % (
                                    registry,
                                    repo_name,
                                    tag,
                                    str(exc),
                                    registry
                                )
                            )
                        else:
                            self.fail(
                                "Error pushing image %s/%s:%s - %s. Does the repository exist?" % (
                                    registry,
                                    repo_name,
                                    tag,
                                    str(exc)
                                )
                            )
                    
                    self.fail(
                        "Error pushing image %s: %s" % (repository, str(exc))
                    )
                    
                self.results['image'] = self.client.find_image(
                    name    = repository,
                    tag     = tag
                )
                
                if not self.results['image']:
                    self.results['image'] = dict()
                
                self.results['image']['push_status'] = status
    
    
    def tag_image(self, name, tag, repository, force=False, push=False):
        '''
        Tag an image into a repository.

        :param name: name of the image. required.
        :param tag: image tag.
        :param repository: path to the repository. required.
        :param force: bool. force tagging, even it image already exists with the repository path.
        :param push: bool. push the image once it's tagged.
        :return: None
        '''
        repo, repo_tag = parse_repository_tag(repository)
        
        if not repo_tag:
            repo_tag = "latest"
            if tag:
                repo_tag = tag
        
        image = self.client.find_image(name=repo, tag=repo_tag)
        
        found = 'found' if image else 'not found'
        
        self.logger.info(
            "image `{repo}` was `{found}`",
            payload = dict(
                repo    = repo,
                found   = found
            )
        )

        if not image or force:
            self.logger.info(
                "tagging {name}:{tag} to {repo}:{repo_tag}",
                payload=dict(name=name, tag=tag, repo=repo, repo_tag=repo_tag)
            )
            
            self.results['changed'] = True
            
            append_action(
                "Tagged image {name}:{tag} to {repo}:{repo_tag}",
                name=name, tag=tag, repo=repo, repo_tag=repo_tag
            )
            
            if not self.check_mode:
                try:
                    # Finding the image does not always work, especially running a localhost registry. In those
                    # cases, if we don't set force=True, it errors.
                    image_name = name
                    if tag and not re.search(tag, name):
                        image_name = "%s:%s" % (name, tag)
                    tag_status = self.client.tag(image_name, repo, tag=repo_tag, force=True)
                    if not tag_status:
                        raise Exception("Tag operation failed.")
                except Exception as exc:
                    self.fail("Error: failed to tag image - %s" % str(exc))
                self.results['image'] = self.client.find_image(name=repo, tag=repo_tag)
                if push:
                    self.push_image(repo, repo_tag)
    
    
    def build_image(self):
        '''
        Build an image

        :return: image dict
        '''
        params = dict(
            path=self.path,
            tag=self.name,
            rm=self.rm,
            nocache=self.nocache,
            # stream=True,
            timeout=self.http_timeout,
            pull=self.pull,
            forcerm=self.rm,
            dockerfile=self.dockerfile,
            decode=True
        )
        build_output = []
        if self.tag:
            params['tag'] = "%s:%s" % (self.name, self.tag)
        if self.container_limits:
            params['container_limits'] = self.container_limits
        if self.buildargs:
            for key, value in self.buildargs.items():
                self.buildargs[key] = to_native(value)
            params['buildargs'] = self.buildargs
        
        self.logger.info(
            "Building",
            payload=params,
        )
        
        logs = self.client.build(**params)
        
        # self.logger.info("build result", payload=dict(result=result))
        
        for log in logs:
            
            self.out(log)
            
            if "stream" in log:
                build_output.append(log["stream"])
                
            if log.get('error'):
                if log.get('errorDetail'):
                    errorDetail = log.get('errorDetail')
                    self.fail(
                        "Error building %s - code: %s, message: %s, logs: %s" % (
                            self.name,
                            errorDetail.get('code'),
                            errorDetail.get('message'),
                            build_output
                        )
                    )
                else:
                    self.fail(
                        "Error building %s - message: %s, logs: %s" % (
                            self.name,
                            log.get('error'),
                            build_output
                        )
                    )
        return self.client.find_image(name=self.name, tag=self.tag)
    
    
    def load_image(self):
        '''
        Load an image from a .tar archive

        :return: image dict
        '''
        try:
            self.logger.info(
                "Opening image `{load_path}`",
                payload = dict(load_path=self.load_path)
            )
            
            image_tar = open(self.load_path, 'r')
            
        except Exception as exc:
            self.fail(
                "Error opening image `{load_path}` - `{error}`",
                load_path   = self.load_path,
                error       = str(exc)
            )

        try:
            self.logger.info(
                "Loading image from `{load_path}`",
                payload = dict(load_path=self.load_path)
            )
            
            self.client.load_image(image_tar)
            
        except Exception as exc:
            self.fail("Error loading image %s - %s" % (self.name, str(exc)))

        try:
            image_tar.close()
        except Exception as exc:
            self.fail("Error closing image %s - %s" % (self.name, str(exc)))

        return self.client.find_image(self.name, self.tag)
