"""tablero.py — Tablero interactivo en Dash para el TP Final.

Contiene:
- Constantes de diseño: paleta categórica validada para daltonismo (azul = PSG,
  naranja = vincha), tintas y fondo.
- filtrar(): aplica los filtros de sexo, grupo etario, IMC, tercio y calidad al cubo.
- fig_sensibilidad(), fig_confusion(), fig_edad(): los tres gráficos del tablero.
- kpis(): las tarjetas con el κ de cada dispositivo (números grandes).
- crear_app(datos): arma el diseño (título con el mensaje, filtros, tarjetas y
  gráficos) y el callback que recalcula todo al cambiar un filtro. Recibe el cubo
  leído del almacén con dw_cubo.sql.
"""
import numpy as np
import pandas as pd
import plotly.graph_objects as go
from dash import Dash, dcc, html, Input, Output

from metricas import concordancia

ORDEN_ESTADIOS = ["W", "N1", "N2", "N3", "REM"]
COLOR = {"PSG": "#2a78d6", "Vincha": "#eb6834"}          # Paleta categórica validada (CVD)
TINTA, TINTA_SECUNDARIA, FONDO = "#0b0b0b", "#52514e", "#fcfcfb"
DISPOSITIVOS = ["PSG", "Vincha"]
GRUPOS = ["18-30", "31-45", "46-60", ">60"]
IMC = ["Bajo peso", "Normal", "Sobrepeso", "Obesidad"]
TERCIOS = ["Primer tercio", "Segundo tercio", "Tercer tercio"]
FUENTE = "Helvetica, Arial, sans-serif"

def coma(x: float, decimales: int = 2) -> str:
    return f"{x:.{decimales}f}".replace(".", ",")

def filtrar(df, sexos, grupos, imcs, tercios, solo_validas):
    m = (df["sexo"].isin(sexos) & df["grupo_etario"].isin(grupos)
         & df["categoria_imc"].isin(imcs) & df["tercio"].isin(tercios))
    if solo_validas:
        m &= df["noche_valida"] == 1
    return df[m]

def estilo(fig, titulo, alto=360):
    fig.update_layout(title=dict(text=titulo, x=0, font=dict(size=15, color=TINTA)), height=alto,
                      template="simple_white", font=dict(family=FUENTE, color=TINTA_SECUNDARIA, size=12),
                      plot_bgcolor=FONDO, paper_bgcolor=FONDO, margin=dict(l=50, r=20, t=60, b=45),
                      legend=dict(orientation="h", y=1.02, yanchor="bottom", x=1, xanchor="right", title=None),
                      hoverlabel=dict(bgcolor="white", font_family=FUENTE),
                      separators=",.")                       # Coma decimal, punto de miles
    return fig

def figura_vacia(titulo):
    fig = go.Figure().add_annotation(text="Sin épocas para los filtros elegidos", showarrow=False,
                                     font=dict(size=14, color=TINTA_SECUNDARIA))
    fig.update_xaxes(visible=False).update_yaxes(visible=False)
    return estilo(fig, titulo)

def fig_sensibilidad(df):
    titulo = "<b>Las dos IA reconocen W, N2 y REM; la vincha pierde en N3</b>"
    if df.empty:
        return figura_vacia(titulo)
    sens = (df.assign(acierto=df["n"].where(df["referencia"] == df["prediccion"], 0))
              .groupby(["dispositivo", "referencia"])[["acierto", "n"]].sum())
    sens = (sens["acierto"] / sens["n"]).unstack("referencia").reindex(columns=ORDEN_ESTADIOS)
    fig = go.Figure()
    for disp in DISPOSITIVOS:
        if disp not in sens.index:
            continue
        valores = sens.loc[disp]
        fig.add_bar(x=ORDEN_ESTADIOS, y=valores, name=disp, marker_color=COLOR[disp],
                    marker_opacity=[1.0 if e == "N3" else 0.35 for e in ORDEN_ESTADIOS],
                    text=[f"{coma(100 * v, 0)} %" if e == "N3" else "" for e, v in valores.items()],
                    textposition="outside", textfont=dict(color=TINTA),
                    hovertemplate=f"{disp}<br>%{{x}}: %{{y:.1%}} de las épocas reconocidas<extra></extra>")
    if set(DISPOSITIVOS) <= set(sens.index) and sens.loc[DISPOSITIVOS, "N3"].notna().all():
        dif = 100 * (sens.loc["Vincha", "N3"] - sens.loc["PSG", "N3"])
        fig.add_annotation(x="N3", y=1.08, text=f"<b>{coma(dif, 0).replace('-', '−')} pp</b> vincha vs. PSG",
                           showarrow=False, font=dict(color=TINTA, size=12))
    fig.update_layout(barmode="group", bargap=0.3, bargroupgap=0.08)
    fig.update_yaxes(range=[0, 1.15], tickformat=".0%", title="Sensibilidad", showgrid=False)
    fig.update_xaxes(title="Estadio según el consenso de expertos")
    return estilo(fig, titulo)

def fig_confusion(df, disp):
    titulo = f"<b>¿Con qué estadio se confunde cada uno? ({disp})</b>"
    d = df[df["dispositivo"] == disp]
    if d.empty:
        return figura_vacia(titulo)
    m = (d.pivot_table(index="referencia", columns="prediccion", values="n", aggfunc="sum", fill_value=0)
          .reindex(index=ORDEN_ESTADIOS, columns=ORDEN_ESTADIOS, fill_value=0))
    pct = m.div(m.sum(axis=1).replace(0, np.nan), axis=0)
    fig = go.Figure(go.Heatmap(
        z=pct.values, x=ORDEN_ESTADIOS, y=ORDEN_ESTADIOS, zmin=0, zmax=1, xgap=2, ygap=2,
        colorscale=[[0, "#f1f6fd"], [1, "#0d3f7a"]], colorbar=dict(title="% fila", tickformat=".0%"),
        text=[[coma(100 * v, 0) if pd.notna(v) else "" for v in fila] for fila in pct.values],
        texttemplate="%{text}", customdata=m.values,
        hovertemplate="Consenso: %{y}<br>IA: %{x}<br>%{z:.1%} de la fila (%{customdata:,} épocas)<extra></extra>"))
    fig.update_yaxes(autorange="reversed", title="Consenso de expertos")
    fig.update_xaxes(title="Estadio asignado por la IA", side="bottom")
    return estilo(fig, titulo)

def fig_edad(df):
    titulo = "<b>Concordancia (κ) por grupo etario</b>"
    if df.empty:
        return figura_vacia(titulo)
    k = df.groupby(["grupo_etario", "dispositivo"]).apply(concordancia, include_groups=False)["kappa"].unstack()
    k = k.reindex([g for g in GRUPOS if g in k.index])
    fig = go.Figure()
    for disp in DISPOSITIVOS:
        if disp in k.columns:
            fig.add_scatter(x=k.index, y=k[disp], name=disp, mode="lines+markers",
                            line=dict(color=COLOR[disp], width=2), marker=dict(size=9, color=COLOR[disp]),
                            hovertemplate=f"{disp}<br>%{{x}}: κ = %{{y:.3f}}<extra></extra>")
    fig.update_yaxes(title="κ de Cohen", range=[0.6, 0.9], showgrid=True, gridcolor="#ececea")
    fig.update_xaxes(title="Grupo etario (años)")
    return estilo(fig, titulo)

def tarjeta(etiqueta, valor, color, tamano="48px"):
    return html.Div([
        html.Div(etiqueta, style={"fontSize": "13px", "color": TINTA_SECUNDARIA}),
        html.Div(valor, style={"fontSize": tamano, "fontWeight": 600, "color": TINTA, "lineHeight": "1.1"}),
        html.Div(style={"height": "4px", "width": "48px", "borderRadius": "2px", "background": color,
                        "marginTop": "6px"}),
    ], style={"padding": "12px 20px", "minWidth": "160px"})

def kpis(df):
    tarjetas = []
    for disp in DISPOSITIVOS:
        d = df[df["dispositivo"] == disp]
        valor = coma(concordancia(d)["kappa"]) if not d.empty else "–"
        tarjetas.append(tarjeta(f"κ de Cohen · {disp}", valor, COLOR[disp]))
    epocas_txt = f"{int(df['n'].sum()):,}".replace(",", ".")
    tarjetas.append(tarjeta("Épocas comparadas", epocas_txt, "#d6d5d0", tamano="28px"))
    return tarjetas


def control(etiqueta, componente):
    return html.Div([html.Label(etiqueta, style={"fontSize": "12px", "color": TINTA_SECUNDARIA}), componente],
                    style={"marginRight": "24px", "minWidth": "150px"})


def crear_app(datos: pd.DataFrame) -> Dash:
    """Crea la aplicación Dash a partir del cubo de concordancia."""
    app = Dash(__name__)
    app.layout = html.Div(style={"fontFamily": FUENTE, "background": FONDO, "padding": "16px", "color": TINTA}, children=[
        html.H2("La vincha wearable estadifica el sueño casi tan bien como el PSG clínico, "
                "pero pierde precisión en el sueño profundo (N3)", style={"fontSize": "22px", "marginBottom": "4px"}),
        html.P("Concordancia de la IA de cada dispositivo con el consenso de tres expertos (AASM). "
               "BOAS, OpenNeuro ds005555: 128 noches de 100 personas.",
               style={"color": TINTA_SECUNDARIA, "marginTop": 0}),
        html.Div(style={"display": "flex", "flexWrap": "wrap", "alignItems": "flex-end", "margin": "12px 0"}, children=[
            control("Sexo", dcc.Checklist(id="f-sexo", options=["F", "M"], value=["F", "M"], inline=True)),
            control("Grupo etario", dcc.Dropdown(id="f-grupo", options=GRUPOS + ["Sin dato"],
                                                 value=GRUPOS + ["Sin dato"], multi=True)),
            control("Categoría de IMC", dcc.Dropdown(id="f-imc", options=IMC + ["Sin dato"],
                                                     value=IMC + ["Sin dato"], multi=True)),
            control("Tercio de la noche", dcc.Checklist(id="f-tercio", options=TERCIOS, value=TERCIOS)),
            control("Calidad", dcc.Checklist(id="f-validas", options=[{"label": " Solo noches con ≥ 4 h válidas",
                                                                       "value": "si"}], value=["si"])),
        ]),
        html.Div(id="kpis", style={"display": "flex", "flexWrap": "wrap", "gap": "8px", "marginBottom": "8px"}),
        html.Div(style={"display": "flex", "flexWrap": "wrap"}, children=[
            html.Div(dcc.Graph(id="g-sensibilidad", config={"displaylogo": False}), style={"flex": "1 1 520px"}),
            html.Div([dcc.RadioItems(id="f-disp", options=DISPOSITIVOS, value="Vincha", inline=True),
                      dcc.Graph(id="g-confusion", config={"displaylogo": False})], style={"flex": "1 1 420px"}),
        ]),
        dcc.Graph(id="g-edad", config={"displaylogo": False}),
    ])

    @app.callback(Output("kpis", "children"), Output("g-sensibilidad", "figure"),
                  Output("g-confusion", "figure"), Output("g-edad", "figure"),
                  Input("f-sexo", "value"), Input("f-grupo", "value"), Input("f-imc", "value"),
                  Input("f-tercio", "value"), Input("f-validas", "value"), Input("f-disp", "value"))
    def actualizar(sexos, grupos, imcs, tercios, validas, disp):
        df = filtrar(datos, sexos or [], grupos or [], imcs or [], tercios or [], bool(validas))
        return kpis(df), fig_sensibilidad(df), fig_confusion(df, disp), fig_edad(df)

    return app
