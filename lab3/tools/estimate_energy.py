#!/usr/bin/env python3
"""Reproduce the hypothetical model in lab3/INFORME.md; not measured current."""
import csv
import sys

RX_MA = 74.0
SLEEP_MA = 0.180
ACTIVE_S = 0.010
CAPACITY_MAH = 3000.0


def main():
    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(["poll_s", "active_fraction", "estimated_current_mA",
                     "ideal_life_h", "ideal_life_days"])
    for period_s in (1, 5, 15):
        fraction = ACTIVE_S / period_s
        current = fraction * RX_MA + (1 - fraction) * SLEEP_MA
        hours = CAPACITY_MAH / current
        writer.writerow([period_s, f"{fraction:.8f}", f"{current:.6f}",
                         f"{hours:.2f}", f"{hours / 24:.2f}"])


if __name__ == "__main__":
    main()
