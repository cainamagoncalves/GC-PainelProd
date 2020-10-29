from flask import render_template
from flask import current_app as app

@app.route('/')
def home():
    return render_template(
        'index.jinja2',
        title='Painel de Produção',
        description='Embed Plotly Dash into your Flask applications.',
        template='home-template',
        body="This is a homepage served with Flask."
    )

@app.errorhandler(404)
def page_not_found(e):
  return render_template('e404.jinja2'), 404

