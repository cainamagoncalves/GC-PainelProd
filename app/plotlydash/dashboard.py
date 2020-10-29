import dash
import dash_html_components as html
import dash_core_components as dcc
import dash_bootstrap_components as dbc
from .layout import html_layout

def init_dashboard(server):
    dash_app = dash.Dash(
        server=server,
        routes_pathname_prefix='/dashapp/',
        suppress_callback_exceptions=True,
        external_scripts=[
            './static/css/style.css',
            dbc.themes.DARKLY
        ],
        title='Painel de Produção'
    )

    # Custom HTML layout
    dash_app.index_string = html_layout

    # Create Layout
    dash_app.layout = html.Div(
        html.P("Glass Control"),
        id='dash-container'
    )

    return dash_app.server
