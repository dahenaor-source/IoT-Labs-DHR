#!/usr/bin/env python3
"""Decode only the two Lab 3 CBOR contracts, without extra dependencies."""
import argparse
import json
import struct


def decode(payload: str) -> dict:
    data = bytes.fromhex(payload)
    if len(data) == 6 and data[:4] == bytes.fromhex("a16174f9"):
        return {"t": struct.unpack(">e", data[4:])[0]}
    if len(data) == 4 and data[:3] == bytes.fromhex("a16176") and data[3] in (0, 1):
        return {"v": data[3]}
    raise ValueError("El payload no coincide con los contratos de temperatura o válvula del Lab 3")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hex", help="Payload hexadecimal; usa comillas si contiene espacios")
    args = parser.parse_args()
    try:
        print(json.dumps(decode(args.hex), ensure_ascii=False))
    except ValueError as exc:
        parser.error(str(exc))
