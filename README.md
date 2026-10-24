# Toolshop Environment

A throwaway local copy of the [Practice Software Testing "Toolshop"](https://practicesoftwaretesting.com) demo shop,
for running end-to-end tests from any framework (Selenide, Playwright, Cypress, pytest, ...).

It runs the shop's own published Docker images, so the pages, API and demo data match the public site.

**Why not just use the public site?** It is shared, resets its data every hour, locks accounts after repeated wrong
passwords, and shows a Cloudflare "Verify you are human" check to browsers running on CI servers. A local copy
avoids all of that, and every start gives a clean database.

| Service | URL |
|---|---|
| Web app | http://localhost:4200 |
| REST API | http://localhost:8091 |
| API docs (Swagger) | http://localhost:8091/api/documentation |

Images: `testsmith/practice-software-testing-sprint5-ui` and `-api` at release **2.5**, nginx, MariaDB 10.6.

## Use it in GitHub Actions

```yaml
steps:
  - uses: IvanKyuchukov98/toolshop-environment@v1
    id: toolshop

  - run: <your test command>
    env:
      UI_BASE_URL: ${{ steps.toolshop.outputs.ui-url }}
      API_BASE_URL: ${{ steps.toolshop.outputs.api-url }}
```

The action starts the shop, loads the demo data and waits until both the web app and the API respond
(usually 2–3 minutes, most of it the web app compiling). It then loads the shop once in headless Chrome and
waits until products are shown, so the slow first page load doesn't land on your tests.
If startup fails, it prints the containers' logs.

## Use it locally

Requires Docker with Compose v2.

```bash
./scripts/start.sh   # start, load fresh demo data, wait until ready
./scripts/stop.sh    # stop and delete all data
```

Running `start.sh` again while the shop is up resets the database to the demo data.

## Demo accounts

| Role | Email | Password |
|---|---|---|
| Admin | admin@practicesoftwaretesting.com | welcome01 |
| Customer | customer@practicesoftwaretesting.com | welcome01 |
| Customer | customer2@practicesoftwaretesting.com | welcome01 |
| Customer | customer3@practicesoftwaretesting.com | pass123 |

## Credits

The Toolshop is built and maintained by [Testsmith](https://github.com/testsmith-io/practice-software-testing).
This repository only wires its published images together for test runs.
