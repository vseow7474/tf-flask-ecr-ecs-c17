from flask import Flask # type: ignore

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, Seow Chee Teck!</p>"

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080)