postgresql:
  pkg.installed

/etc/postgresql/9.5/main/pg_hba.conf:
  file.managed:
    - source: salt://pg_hba.conf

/etc/postgresql/9.5/main/postgresql.conf:
  file.managed:
    - source: salt://postgresql.conf

postgresql.service:
  service.running:
    - enable: True
    - restart: True
    - require:
      - pkg: postgresql
    - watch:
      - file: /etc/postgresql/9.5/main/pg_hba.conf
      - file: /etc/postgresql/9.5/main/postgresql.conf

copy database dump:
  file.managed:
    - name: /database.dump
    - source: salt://database.dump
    - require:
      - pkg: postgresql

import database dump:
  cmd.run:
    - name: psql -d overwatch < /database.dump >/dev/null
    - runas: postgres
    - onlyif: createdb overwatch
    - require:
      - file: copy database dump
