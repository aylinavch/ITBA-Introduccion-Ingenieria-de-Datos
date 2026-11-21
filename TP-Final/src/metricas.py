"""metricas.py — Métricas de sueño y de concordancia entre evaluadores.

- resumir_noche(g): indicadores de una noche a partir de sus épocas (arquitectura del
  sueño sobre el consenso humano, horas válidas y κ de Cohen de cada IA).
- concordancia(df): acuerdo y κ de Cohen a partir de los conteos de una matriz de
  confusión (columnas referencia, prediccion, n). Se usa con el cubo del almacén:
  como κ no es aditivo, se calcula después de sumar los conteos de cada corte.
"""
import numpy as np
import pandas as pd
from sklearn.metrics import cohen_kappa_score

SUENO = [1, 2, 3, 4]   # N1, N2, N3, REM

def resumir_noche(g: pd.DataFrame) -> pd.Series:
    hum = g["stage_hum"]
    dormido = hum.isin(SUENO).to_numpy()
    r = {"horas_registro": len(g) / 120, "tst_min": dormido.sum() / 2,
         "eficiencia": dormido.sum() / hum.notna().sum(),
         "pct_artefacto_hb": g["stage_ai_hb"].isna().mean() * 100}
    if dormido.any():
        i0, i1 = dormido.argmax(), len(dormido) - 1 - dormido[::-1].argmax()
        r["latencia_sueno_min"] = i0 / 2 if i0 > 0 else np.nan   # Sin vigilia inicial → no calculable
        rem = (hum.to_numpy() == 4)
        r["latencia_rem_min"] = (rem[i0:].argmax()) / 2 if rem.any() else np.nan
        r["waso_min"] = (hum.iloc[i0:i1 + 1] == 0).sum() / 2
    for disp in ["psg", "hb"]:
        ia = g[f"stage_ai_{disp}"]
        ok = hum.notna() & ia.notna()
        r[f"horas_validas_{disp}"] = ok.sum() / 120
        r[f"kappa_{disp}"] = cohen_kappa_score(hum[ok].astype(int), ia[ok].astype(int))
    return pd.Series(r)


def concordancia(df: pd.DataFrame) -> pd.Series:
    """Acuerdo y κ de Cohen a partir de conteos de una matriz de confusión."""
    n = df["n"].sum()
    p_o = df.loc[df["referencia"] == df["prediccion"], "n"].sum() / n
    marg_ref = df.groupby("referencia")["n"].sum() / n
    marg_pred = df.groupby("prediccion")["n"].sum() / n
    p_e = (marg_ref * marg_pred.reindex(marg_ref.index, fill_value=0)).sum()
    return pd.Series({"epocas": int(n), "acuerdo": p_o, "kappa": (p_o - p_e) / (1 - p_e)})
