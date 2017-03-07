install python3, flask and psycopg2:
  pkg.installed:
    - pkgs:
      - python3
      - python3-flask
      - python3-psycopg2

copy program sources:
  file.recurse:
    - name: /app
    - source: salt://web/src

fix permissions:
  file.managed:
    - name: /app/server.py
    - mode: 755
    - require:
      - file: copy program sources

install service:
  file.managed:
    - name: /etc/systemd/system/web.service
    - source: salt://web/web.service

web.service:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: copy program sources
      - file: install service
