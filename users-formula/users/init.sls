include:
  - users.sudo

{% for name, user in pillar.get('users', {}).items() %}
{%- if user == None -%}
{%- set user = {} -%}
{%- endif -%}
{%- set home = user.get('home', "/home/%s" % name) -%}

{%- if 'prime_group' in user and 'name' in user['prime_group'] %}
{%- set user_group = user.prime_group.name -%}
{%- else -%}
{%- set user_group = name -%}
{%- endif %}

{% for group in user.get('groups', []) %}
{{ name }}_{{ group }}_group:
  group:
    - name: {{ group }}
    - present
{% endfor %}

{{ name }}_user:
  file.directory:
    - name: {{ home }}
    - user: {{ name }}
    - group: {{ user_group }}
    - mode: 0755
    - require:
      - user: {{ name }}
      - group: {{ user_group }}
  group.present:
    - name: {{ user_group }}
    {%- if 'prime_group' in user and 'gid' in user['prime_group'] %}
    - gid: {{ user['prime_group']['gid'] }}
    {%- elif 'uid' in user %}
    - gid: {{ user['uid'] }}
    {%- endif %}
  user.present:
    - name: {{ name }}
    - home: {{ home }}
    - shell: {{ user.get('shell', '/bin/bash') }}
    {% if 'uid' in user -%}
    - uid: {{ user['uid'] }}
    {% endif -%}
    {% if 'prime_group' in user and 'gid' in user['prime_group'] -%}
    - gid: {{ user['prime_group']['gid'] }}
    {% else -%}
    - gid_from_name: True
    {% endif -%}
    {% if 'fullname' in user %}
    - fullname: {{ user['fullname'] }}
    {% endif %}
    {% if 'hash' in user %}
    - password: {{ user['hash'] }}
    {% endif %}
    - system: {{ user.get('system', False) }}
    - groups:
      - {{ user_group }}
      {% for group in user.get('groups', []) -%}
      - {{ group }}
      {% endfor %}
    - require:
      - group: {{ user_group }}
      {% for group in user.get('groups', []) -%}
      - group: {{ group }}
      {% endfor %}

user_keydir_{{ name }}:
  file.directory:
    - name: {{ user.get('home', '/home/{0}'.format(name)) }}/.ssh
    - user: {{ name }}
    - group: {{ user_group }}
    - makedirs: True
    - mode: 700
    - require:
      - user: {{ name }}
      - group: {{ user_group }}
      {%- for group in user.get('groups', []) %}
      - group: {{ group }}
      {%- endfor %}

  {% if 'ssh_keys' in user %}
  {% set key_type = 'id_' + user.get('ssh_key_type', 'rsa') %}
user_{{ name }}_private_key:
  file.managed:
    - name: {{ user.get('home', '/home/{0}'.format(name)) }}/.ssh/{{ key_type }}
    - user: {{ name }}
    - group: {{ user_group }}
    - mode: 600
    - contents_pillar: users:{{ name }}:ssh_keys:privkey
    - require:
      - user: {{ name }}_user
      {% for group in user.get('groups', []) %}
      - group: {{ name }}_{{ group }}_group
      {% endfor %}
user_{{ name }}_public_key:
  file.managed:
    - name: {{ user.get('home', '/home/{0}'.format(name)) }}/.ssh/{{ key_type }}.pub
    - user: {{ name }}
    - group: {{ user_group }}
    - mode: 644
    - contents_pillar: users:{{ name }}:ssh_keys:privkey
    - require:
      - user: {{ name }}_user
      {% for group in user.get('groups', []) %}
      - group: {{ name }}_{{ group }}_group
      {% endfor %}
  {% endif %}


  {% if 'ssh_auth' in user %}
  {% for auth in user['ssh_auth'] %}
ssh_auth_{{ name }}_{{ loop.index0 }}:
  ssh_auth.present:
    - user: {{ name }}
    - name: {{ auth }}
    - require:
        - file: {{ name }}_user
        - user: {{ name }}_user
{% endfor %}
{% endif %}

{% if 'dotfiles' in user %}
{% set dotfiles_dir = home ~ '/.dotfiles' %}

{{ dotfiles_dir }}:
  file.directory:
    - user: {{ name }}
    - group: {{ name }}
    - makedirs: True
    - require:
      - user: {{ name }}_user
      {% for group in user.get('groups', []) %}
      - group: {{ group }}_group
      {% endfor %}

{{ user['dotfiles']['repository'] }}_{{ name }}:
  git.latest:
    - name: {{ user['dotfiles']['repository'] }}
    - target: {{ dotfiles_dir }}
    - user: {{ name }}
    - require:
      - file: {{ dotfiles_dir }}

{{ user['dotfiles']['install_cmd'] }}_{{ name }}:
  cmd.wait:
    - name: {{ user['dotfiles']['install_cmd'] }}
    - user: {{ name }}
    - cwd: {{ dotfiles_dir }}
    - watch:
      - git: {{ user['dotfiles']['repository'] }}_{{ name }}

{% endif %}

{% if 'sudouser' in user and user['sudouser'] %}
sudoer-{{ name }}:
  file.managed:
    - name: /etc/sudoers.d/{{ name }}
    - user: root
    - group: root
    - mode: '0440'
{% if 'sudo_rules' in user %}
/etc/sudoers.d/{{ name }}:
  file.append:
    - text:
      {% for rule in user['sudo_rules'] %}
      - "{{ name }} {{ rule }}"
      {% endfor %}
    - require:
      - file: sudoer-defaults
      - file: sudoer-{{ name }}
{% endif %}
{% else %}
/etc/sudoers.d/{{ name }}:
  file.absent:
    - name: /etc/sudoers.d/{{ name }}
{% endif %}

# Install system packages requested by a user.
# Yes, this fork to the users formula assumes system users are trusted.
{% for pkg in user.get('uses_sys_packages', []) %}
{{ name }}-sys_pkg-{{ pkg }}:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}

{% endfor %}

{% for user in pillar.get('absent_users', []) %}
{{ user }}:
  user.absent
/etc/sudoers.d/{{ user }}:
  file.absent:
    - name: /etc/sudoers.d/{{ user }}
{% endfor %}
