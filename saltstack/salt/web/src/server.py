#!/usr/bin/env python3

import flask
import psycopg2

conn = psycopg2.connect("dbname=overwatch host=database.example.internal user=postgres")

app = flask.Flask('web')

@app.route("/")
def root():
    cur = conn.cursor()
    cur.execute("""
        SELECT message FROM motd
        """)
    (message,) = cur.fetchone()
    return flask.jsonify({"message": message})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=True)
    conn.close()
