#!/usr/bin/python
#
# Copyright 2016 Red Hat | Ansible
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type


ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}


DOCUMENTATION = '''
---
module: qb_docker_image

short_description: QB extension of Ansible's `docker_image` module.

description:
     - Build, load or pull an image, making the image available for creating containers. Also supports tagging an
       image into a repository and archiving an image to a .tar file.

options:
  archive_path:
    description:
      - Use with state C(present) to archive an image to a .tar file.
    required: false
    version_added: "2.1"
  load_path:
    description:
      - Use with state C(present) to load an image from a .tar file.
    required: false
    version_added: "2.2"
  dockerfile:
    description:
      - Use with state C(present) to provide an alternate name for the Dockerfile to use when building an image.
    default: Dockerfile
    required: false
    version_added: "2.0"
  force:
    description:
      - Use with state I(absent) to un-tag and remove all images matching the specified name. Use with state
        C(present) to build, load or pull an image when the image already exists.
    default: false
    required: false
    version_added: "2.1"
    type: bool
  http_timeout:
    description:
      - Timeout for HTTP requests during the image build operation. Provide a positive integer value for the number of
        seconds.
    required: false
    version_added: "2.1"
  name:
    description:
      - "Image name. Name format will be one of: name, repository/name, registry_server:port/name.
        When pushing or pulling an image the name can optionally include the tag by appending ':tag_name'."
    required: true
  path:
    description:
      - Use with state 'present' to build an image. Will be the path to a directory containing the context and
        Dockerfile for building an image.
    aliases:
      - build_path
    required: false
  pull:
    description:
      - When building an image downloads any updates to the FROM image in Dockerfile.
    default: true
    required: false
    version_added: "2.1"
    type: bool
  push:
    description:
      - Push the image to the registry. Specify the registry as part of the I(name) or I(repository) parameter.
    default: false
    required: false
    version_added: "2.2"
    type: bool
  rm:
    description:
      - Remove intermediate containers after build.
    default: true
    required: false
    version_added: "2.1"
    type: bool
  nocache:
    description:
      - Do not use cache when building an image.
    default: false
    required: false
    type: bool
  repository:
    description:
      - Full path to a repository. Use with state C(present) to tag the image into the repository. Expects
        format I(repository:tag). If no tag is provided, will use the value of the C(tag) parameter or I(latest).
    required: false
    version_added: "2.1"
  state:
    description:
      - Make assertions about the state of an image.
      - When C(absent) an image will be removed. Use the force option to un-tag and remove all images
        matching the provided name.
      - When C(present) check if an image exists using the provided name and tag. If the image is not found or the
        force option is used, the image will either be pulled, built or loaded. By default the image will be pulled
        from Docker Hub. To build the image, provide a path value set to a directory containing a context and
        Dockerfile. To load an image, specify load_path to provide a path to an archive file. To tag an image to a
        repository, provide a repository path. If the name contains a repository path, it will be pushed.
      - "NOTE: C(build) is DEPRECATED and will be removed in release 2.3. Specifying C(build) will behave the
         same as C(present)."
    required: false
    default: present
    choices:
      - absent
      - present
      - build
  tag:
    description:
      - Used to select an image when pulling. Will be added to the image when pushing, tagging or building. Defaults to
        I(latest).
      - If C(name) parameter format is I(name:tag), then tag value from C(name) will take precedence.
    default: latest
    required: false
  buildargs:
    description:
      - Provide a dictionary of C(key:value) build arguments that map to Dockerfile ARG directive.
      - Docker expects the value to be a string. For convenience any non-string values will be converted to strings.
      - Requires Docker API >= 1.21 and docker-py >= 1.7.0.
    required: false
    version_added: "2.2"
  container_limits:
    description:
      - A dictionary of limits applied to each container created by the build process.
    required: false
    version_added: "2.1"
    suboptions:
      memory:
        description:
          - Set memory limit for build.
      memswap:
        description:
          - Total memory (memory + swap), -1 to disable swap.
      cpushares:
        description:
          - CPU shares (relative weight).
      cpusetcpus:
        description:
          - CPUs in which to allow execution, e.g., "0-3", "0,1".
  use_tls:
    description:
      - "DEPRECATED. Whether to use tls to connect to the docker server. Set to C(no) when TLS will not be used. Set to
        C(encrypt) to use TLS. And set to C(verify) to use TLS and verify that the server's certificate is valid for the
        server. NOTE: If you specify this option, it will set the value of the tls or tls_verify parameters."
    choices:
      - no
      - encrypt
      - verify
    default: no
    required: false
    version_added: "2.0"
  try_to_pull:
    description:
      - Try to pull the image before building. Added by QB.
    choices:
      - yes
      - no
    default: yes
    required: false

extends_documentation_fragment:
    - docker

requirements:
  - "python >= 2.6"
  - "docker-py >= 1.7.0"
  - "Docker API >= 1.20"

author:
  - Pavel Antonov (@softzilla)
  - Chris Houseknecht (@chouseknecht)
  - James Tanner (@jctanner)

'''

EXAMPLES = '''

- name: pull an image
  docker_image:
    name: pacur/centos-7

- name: Tag and push to docker hub
  docker_image:
    name: pacur/centos-7
    repository: dcoppenhagan/myimage
    tag: 7.0
    push: yes

- name: Tag and push to local registry
  docker_image:
     name: centos
     repository: localhost:5000/centos
     tag: 7
     push: yes

- name: Remove image
  docker_image:
    state: absent
    name: registry.ansible.com/chouseknecht/sinatra
    tag: v1

- name: Build an image and push it to a private repo
  docker_image:
    path: ./sinatra
    name: registry.ansible.com/chouseknecht/sinatra
    tag: v1
    push: yes

- name: Archive image
  docker_image:
    name: registry.ansible.com/chouseknecht/sinatra
    tag: v1
    archive_path: my_sinatra.tar

- name: Load image from archive and push to a private registry
  docker_image:
    name: localhost:5000/myimages/sinatra
    tag: v1
    push: yes
    load_path: my_sinatra.tar

- name: Build image and with buildargs
  docker_image:
     path: /path/to/build/dir
     name: myimage
     buildargs:
       log_volume: /var/log/myapp
       listen_port: 8080
'''

RETURN = '''
image:
    description: Image inspection results for the affected image.
    returned: success
    type: dict
    sample: {}
'''

import json

# WTF This is some weird trigger?!?!? If this line is *gone*, can't read
# params... but commented out is fine :/
# from ansible.module_utils.docker_common import HAS_DOCKER_PY_2

import qb.ipc.stdio
import qb.ipc.stdio.logging

from qb.ansible.modules.docker.client import QBAnsibleDockerClient
from qb.ansible.modules.docker.image_manager import ImageManager

logger = qb.ipc.stdio.logging.getLogger('qb_docker_image')


def main():
    argument_spec = dict(
        archive_path=dict(type='path'),
        container_limits=dict(type='dict'),
        dockerfile=dict(type='str'),
        force=dict(type='bool', default=False),
        http_timeout=dict(type='int'),
        load_path=dict(type='path'),
        name=dict(type='str', required=True),
        nocache=dict(type='bool', default=False),
        path=dict(type='path', aliases=['build_path']),
        pull=dict(type='bool', default=True),
        push=dict(type='bool', default=False),
        repository=dict(type='str'),
        rm=dict(type='bool', default=True),
        state=dict(
            type='str',
            choices=['absent', 'present', 'build'],
            default='present'
        ),
        tag=dict(type='str', default='latest'),
        use_tls=dict(
            type='str',
            default='no',
            choices=['no', 'encrypt', 'verify']
        ),
        buildargs=dict(type='dict', default=None),
        
        # QB additions
        try_to_pull=dict( type='bool', default=True ),
    )

    client = QBAnsibleDockerClient(
        argument_spec=argument_spec,
        supports_check_mode=True,
        mutually_exclusive=[
            # Don't tell me to build *and* load an image
            ['path', 'load_path'],
        ]
    )

    results = dict(
        changed=False,
        actions=[],
        # NOTE IDK why this is an empty dict...?
        image={},
        warnings=[],
    )
    
    qb.ipc.stdio.client.connect(results['warnings'])
    
    ImageManager(client, results)
    client.module.exit_json(**results)


if __name__ == '__main__':
    main()
