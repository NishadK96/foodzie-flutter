#!/usr/bin/env python3
"""Verify the Flutter POS contract against a disposable local Foodzy backend."""

import argparse
import json
import urllib.error
import urllib.request


def request(base_url, method, path, body=None, headers=None):
    request_headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        **(headers or {}),
    }
    encoded = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        f"{base_url.rstrip('/')}/{path.lstrip('/')}",
        method=method,
        headers=request_headers,
        data=encoded,
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")
        raise RuntimeError(f"{method} {path}: HTTP {error.code}: {detail}") from error


def payload(response):
    return response.get("data", response) if isinstance(response, dict) else response


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="http://127.0.0.1:8080/api/v1")
    parser.add_argument("--email", default="admin@example.com")
    parser.add_argument("--password", required=True)
    args = parser.parse_args()

    _, login = request(
        args.base_url,
        "POST",
        "auth/login",
        {"email": args.email, "password": args.password, "device_name": "POS contract test"},
    )
    headers = {"Authorization": f"Bearer {login['data']['access_token']}"}
    _, context = request(args.base_url, "GET", "auth/me", headers=headers)
    headers["X-Branch-ID"] = str(context["branch"]["id"])

    read_paths = [
        "pos/branches", "pos/categories", "pos/items", "pos/tables",
        "pos/order-types", "pos/taxes", "pos/orders", "pos/kots",
        "pos/customers", "pos/reservations", "platform/printers",
        "platform/receipt-settings", "staff",
    ]
    responses = {}
    for path in read_paths:
        status, responses[path] = request(args.base_url, "GET", path, headers=headers)
        print(f"PASS {status} GET /{path}")

    items = payload(responses["pos/items"])
    tables = payload(responses["pos/tables"])["tables"]
    table = next((row for row in tables if not row.get("is_running")), tables[0])
    status, created = request(
        args.base_url,
        "POST",
        "pos/orders",
        {
            "items": [{"id": items[0]["id"], "quantity": 1, "modifiers": []}],
            "order_type": "Dine In",
            "table_id": table["id"],
            "placed_via": "pos",
            "note": "Automated Flutter POS contract test",
            "actions": ["draft"],
        },
        headers,
    )
    order_id = int(created["order"]["id"])
    print(f"PASS {status} POST /pos/orders -> {order_id}")

    for path, body in [
        (f"pos/orders/{order_id}/kot", {}),
        (f"pos/orders/{order_id}/pay", {"payment_method": "cash"}),
    ]:
        status, _ = request(args.base_url, "POST", path, body, headers)
        print(f"PASS {status} POST /{path}")

    status, _ = request(args.base_url, "GET", f"pos/orders/{order_id}", headers=headers)
    print(f"PASS {status} GET /pos/orders/{order_id}")
    status, kots = request(
        args.base_url, "GET", f"pos/orders/{order_id}/kots", headers=headers
    )
    if not payload(kots):
        raise RuntimeError("The test order has no KOT after KOT creation.")
    print(f"PASS {status} GET /pos/orders/{order_id}/kots")
    print("Foodzy local API contract verified.")


if __name__ == "__main__":
    main()
