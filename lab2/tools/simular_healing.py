#!/usr/bin/env python3
"""Aproximación del healing time del Lab 2 (A-B-C con enlace A-C débil).

Es una estimación, no una captura: modela el apagado de B con constantes típicas de
OpenThread/Thread. Ajustar con valores reales cuando haya tercer nodo.
"""
import random
import statistics as st

MAX_NEIGHBOR_AGE = 100.0   # s sin oír a un vecino router antes de declararlo caído
ADV_IMAX = 32.0            # s, intervalo máximo del trickle de MLE Advertisement
ROUTE_UPDATE = (0.5, 4.0)  # s, A recalcula y usa el enlace débil A-C (trickle reiniciado)
PING_RTT = (0.05, 0.40)    # s, primer eco que vuelve por la ruta A-C (enlace pobre)
META = 120.0               # s, objetivo del curso

def trial(rng):
    edad = rng.uniform(0, ADV_IMAX)          # edad del último frame de B al apagarse
    deteccion = MAX_NEIGHBOR_AGE - edad
    return deteccion + rng.uniform(*ROUTE_UPDATE) + rng.uniform(*PING_RTT)

def main():
    rng = random.Random(2026)
    ensayos = [trial(rng) for _ in range(3)]
    muestras = [trial(rng) for _ in range(10000)]
    muestras.sort()
    print("Ensayos aproximados (s):", ", ".join(f"{x:.1f}" for x in ensayos))
    print(f"Media {st.mean(ensayos):.1f} s, máx {max(ensayos):.1f} s (n=3)")
    print(f"Monte Carlo n=10000: mediana {st.median(muestras):.1f}, "
          f"p95 {muestras[int(0.95*len(muestras))]:.1f}, "
          f"mín {muestras[0]:.1f}, máx {muestras[-1]:.1f}")
    print(f"Fracción < {META:.0f} s: {sum(x < META for x in muestras)/len(muestras):.1%}")

if __name__ == "__main__":
    main()
