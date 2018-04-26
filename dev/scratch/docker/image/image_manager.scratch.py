#!/usr/bin/python
#
# Copyright 2016 Red Hat | Ansible
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

import os
import re
import json
import socket
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

logger = qb.ipc.stdio.logging.getLogger('qb_docker_image')

class ImageManager(DockerBaseClass):

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
            level = logging.DEBUG,
        )

        # If name contains a tag, it takes precedence over tag parameter.
        repo, repo_tag = parse_repository_tag(self.name)
        if repo_tag:
            self.name = repo
            self.tag = repo_tag
        
        self.name_tag = "{}:{}".format(self.name, self.tag)

        if self.state in ['present', 'build']:
            self.present()
        elif self.state == 'absent':
            self.absent()

    def fail(self, msg):
        self.client.fail(msg)

    def present(self):
        '''
        Handles state = 'present', which includes building, loading or pulling
        an image, depending on user provided parameters.

        :returns None
        '''
        
        self.logger.info(
            "Starting state=present...",
            payload = dict(
                name = self.name_tag,
                tag = self.tag,
            )
        )
        
        if self.force:
            if self.path:
                self.logger.info(
                    "FORCING image build",
                    payload=dict(
                        name    = self.name_tag,
                        path    = self.load_path,
                    )
                )
                self.build_image()
            elif self.load_path:
                self.logger.info(
                    "FORCING image load",
                    payload=dict(
                        name        = self.name_tag,
                        load_path   = self.load_path,
                    )
                )
                self.load_image()
            else:
                self.logger.info(
                    "FORCING image pull",
                    payload=dict(
                        name=self.name_tag,
                    )
                )
                self.pull_image()
        else:
            self.existing_image = self.client.find_image(
                name    = self.name,
                tag     = self.tag,
            )
            
            if self.existing_image is None:
                self.logger.info(
                    "Image not found in local Docker daemon"
                )
                
                if self.path or self.load_path:
                    if not self.try_to_pull_image():
                        if self.path:
                            self.build_image()
                        else:
                            self.load_image()
                else:
                    self.pull_image()

        if self.archive_path:
            self.archive_image(self.name, self.tag)
        
        if self.repository:
            self.tag_image(
                self.name,
                self.tag,
                self.repository,
                force   = self.force,
                push    = self.push,
            )
            
        elif self.push and self.pulled_image is None:
            if self.force:
                self.logger.info(
                    "FORCING image push",
                    payload = dict(
                        name    = self.name_tag,
                        
                    )
                )
            elif
            
            
            
        self.push_image()
        
        # Don't
        if self.pulled_image is None:
            
            
            if self.push and not self.repository:
                self.push_image(self.name, self.tag)
            elif self.repository:
                self.tag_image(
                    self.name,
                    self.tag,
                    self.repository,
                    force   = self.force,
                    push    = self.push,
                )
        
        # Only push if:
        # 
        # 1.  We didn't pull the image (if we did pull it we have no need to
        #     then push it).
        # 2.  We have a local image or image result (or what are we pushing)
        # have_image = image or len(self.result['image']) > 0
        # 3.  Either:
        #     A.  We didn't find any image before doing anything
        #     B.  The resulting image is different
        # 
        # image_is_different = (
        #     (not image) or (
        #         len(self.results image[u'Id'] != self.results['image'][u'Id']
        
        
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
            self.results['actions'].append("Removed image %s" % (name))
            self.results['image']['state'] = 'Deleted'
    
    
    def try_to_pull_image(self):
        
    
    
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
            self.log("archive image: image %s:%s not found" % (name, tag))
            return

        image_name = "%s:%s" % (name, tag)
        self.results['actions'].append('Archived image %s to %s' % (image_name, self.archive_path))
        self.results['changed'] = True
        if not self.check_mode:
            self.log("Getting archive of image %s" % image_name)
            try:
                image = self.client.get_image(image_name)
            except Exception as exc:
                self.fail("Error getting image %s - %s" % (image_name, str(exc)))

            try:
                with open(self.archive_path, 'w') as fd:
                    for chunk in image.stream(2048, decode_content=False):
                        fd.write(chunk)
            except Exception as exc:
                self.fail("Error writing image archive %s - %s" % (self.archive_path, str(exc)))

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
        
        if self.pulled_image is not None:
            self.logger.info(
                ""
            )

        repository = name
        if not tag:
            repository, tag = parse_repository_tag(name)
        registry, repo_name = resolve_repository_name(repository)

        self.log("push %s to %s/%s:%s" % (self.name, registry, repo_name, tag))

        if registry:
            self.results['actions'].append("Pushed image %s to %s/%s:%s" % (self.name, registry, repo_name, tag))
            self.results['changed'] = True
            if not self.check_mode:
                status = None
                try:
                    for line in self.client.push(repository, tag=tag, stream=True, decode=True):
                        self.log(line, pretty_print=True)
                        if line.get('errorDetail'):
                            raise Exception(line['errorDetail']['message'])
                        status = line.get('status')
                except Exception as exc:
                    if re.search('unauthorized', str(exc)):
                        if re.search('authentication required', str(exc)):
                            self.fail("Error pushing image %s/%s:%s - %s. Try logging into %s first." %
                                      (registry, repo_name, tag, str(exc), registry))
                        else:
                            self.fail("Error pushing image %s/%s:%s - %s. Does the repository exist?" %
                                      (registry, repo_name, tag, str(exc)))
                    self.fail("Error pushing image %s: %s" % (repository, str(exc)))
                self.results['image'] = self.client.find_image(name=repository, tag=tag)
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
        self.log("image %s was %s" % (repo, found))

        if not image or force:
            self.log("tagging %s:%s to %s:%s" % (name, tag, repo, repo_tag))
            self.results['changed'] = True
            self.results['actions'].append("Tagged image %s:%s to %s:%s" % (name, tag, repo, repo_tag))
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
            stream=True,
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

        for line in self.client.build(**params):
            # line = json.loads(line)
            self.log(line, pretty_print=True)
            if "stream" in line:
                build_output.append(line["stream"])
            if line.get('error'):
                if line.get('errorDetail'):
                    errorDetail = line.get('errorDetail')
                    self.fail(
                        "Error building %s - code: %s, message: %s, logs: %s" % (
                            self.name,
                            errorDetail.get('code'),
                            errorDetail.get('message'),
                            build_output))
                else:
                    self.fail("Error building %s - message: %s, logs: %s" % (
                        self.name, line.get('error'), build_output))
        return self.client.find_image(name=self.name, tag=self.tag)

    def load_image(self):
        '''
        Load an image from a .tar archive

        :return: image dict
        '''
        try:
            self.log("Opening image %s" % self.load_path)
            image_tar = open(self.load_path, 'r')
        except Exception as exc:
            self.fail("Error opening image %s - %s" % (self.load_path, str(exc)))

        try:
            self.log("Loading image from %s" % self.load_path)
            self.client.load_image(image_tar)
        except Exception as exc:
            self.fail("Error loading image %s - %s" % (self.name, str(exc)))

        try:
            image_tar.close()
        except Exception as exc:
            self.fail("Error closing image %s - %s" % (self.name, str(exc)))

        return self.client.find_image(self.name, self.tag)


    def log(self, msg, pretty_print=False):
        return self.client.log(msg)
    
    def warn( self, warning ):
        self.results['warnings'].append( str(warning) )
