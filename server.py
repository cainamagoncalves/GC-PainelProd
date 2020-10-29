from waitress import serve
from app import init_app

app = init_app()

serve(server)
