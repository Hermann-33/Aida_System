# POS / Admin Screenshot Manifest — Closure Gate

Captured: 2026-07-21T12:49:30.229Z
Base URL: http://localhost:5173
Mode: UI PREVIEW — SAMPLE DATA

## Network isolation

- Forbidden API/DB/backend requests: 0 (must be 0)
- External font hosts observed: https://fonts.googleapis.com/css2, https://fonts.gstatic.com/s/plusjakartasans/v12/LDIoaomQNQcsA88c7O9yZ4KMCoOg4Ko20yw.woff2, https://fonts.gstatic.com/s/dancingscript/v29/If2RXTr6YS-zF4S-kcSWSVi_szLgiuE.woff2, https://fonts.gstatic.com/s/playfairdisplay/v40/nuFiD-vYSZviVYUb_rj3ij__anPXDTzYgA.woff2
- Fonts are acceptable per closure-gate rules.

## Screenshots

| Filename | Route | Expected heading | Viewport | SHA-256 | Result |
|---|---|---|---|---|---|
| `03-terminal-activation.png` | `/employee` | Activate this terminal | 1366×768 | `d1001d6f79b9a356a3b65ed27bdaf46b16622ff3dae7d5eb81032905f925a642` | PASS |
| `01-employee-password-login.png` | `/employee` | Sign in | 1366×768 | `7c40b2ebbccb458defbbf5646b391fd14330d390140af8b549548b5e78b01b3a` | PASS |
| `02-employee-badge-pin-login.png` | `/employee` | Sign in (Badge + PIN) | 1366×768 | `67bda7ff5d75c6cc7cf85f3a345edc6967bd9e4ab52e67cd26a26c3da402d0d4` | PASS |
| `04-dual-role-selection.png` | `/employee/select-role` | Choose workspace | 1366×768 | `e6bf9c9e4040c677d57620c2818ad9641ff5fe48bd17cb224490275a298907eb` | PASS |
| `05-unauthorized.png` | `/unauthorized` | Unauthorized | 1366×768 | `54b9388a40e4c869981777dbc2f92a1fe1a193515e1046920c4bd825f5cbaeae` | PASS |
| `10-pos-open-shift.png` | `/pos` | Open shift | 1366×768 | `1880bc2faac3f62b58a0aa9a652ccda1ead1a7a0fa59912e346175564a5bf730` | PASS |
| `11-pos-new-sale.png` | `/pos` | New sale / menu | 1366×768 | `af079163f4b2edaae113e199833c305f8001d08181b4a67b4dbfc7e86cb2e46b` | PASS |
| `12-pos-product-selected.png` | `/pos` | Modifier dialog | 1366×768 | `24a2a565c252b54863d65f95f5514e9754bee659db09461cea5b89df85e6698b` | PASS |
| `13-pos-modifiers.png` | `/pos` | Modifiers | 1366×768 | `506c11d92f7edbbe4bfe4bfbc216c985122284cb50828ba7f827e8b8177f1585` | PASS |
| `14-pos-cart.png` | `/pos` | Cart with item | 1366×768 | `b3831b906bf3d683988283582fd3ca31654aae2407a3abcb42ddef524910b79e` | PASS |
| `15-pos-member-search.png` | `/pos` | Member panel | 1366×768 | `a336ce1f705031e0d4dd7ff91ded745f0a167bf13fa8ec90884b4ac3fb4e5e8c` | PASS |
| `16-pos-student-member.png` | `/pos` | Student member | 1366×768 | `f5f2517f5777f94ea1ec1b110fc3b64ccf1d27719f0f0b6377d3f190e11876f7` | PASS |
| `17-pos-rewards.png` | `/pos` | Rewards applied | 1366×768 | `c4e0aca3dbe5fe29a8eef8191a03cabef34aca0b42050e27d5c164cc7080ad42` | PASS |
| `18-pos-payment.png` | `/pos` | Payment | 1366×768 | `50b4264db92eeceaae2d0e916758a634530080c806ed7f0b0639e5047af0a3b6` | PASS |
| `19-pos-receipt.png` | `/pos` | Receipt / sale complete | 1366×768 | `fd80b0f837a32c0bf5b23322443a8cf5145507a55503232796aeb306557ffc64` | PASS |
| `21-pos-payment-failure.png` | `/pos` | Payment declined | 1366×768 | `e97334e5ec425834fa2fdc4434bb42395d421c1aa65df817ede3952781378c29` | PASS |
| `22-pos-offline-state.png` | `/pos` | Offline / terminal | 1366×768 | `ccd9712beb67a44e62860d40e9c144a62d1a8144110f05904dbdb5d15b4de7ea` | PASS |
| `20-pos-close-shift.png` | `/pos` | Close shift | 1366×768 | `3f35cd864700aea6e21ed56ba3e8d9747b1f56e842b1bb71a69858b2d1c85f91` | PASS |
| `30-admin-dashboard.png` | `/admin` | Executive Dashboard | 1440×900 | `72bbce683169567377d5ecb91457b146d467049468cb5ca3ad71e3bbc2f2d718` | PASS |
| `31-admin-daily-sales.png` | `/admin/reports/sales` | Daily sales report | 1440×900 | `eadb1eed96bf0a212940bdcc77c1289e6df36f950a10a3e3d3b11eb9cab508c2` | PASS |
| `32-admin-monthly-sales.png` | `/admin?period=month` | Executive Dashboard (Month) | 1440×900 | `6afc8c4128a8847b314659e54947aad7085f38c6067ec2b94093cc5a980450db` | PASS |
| `33-admin-branch-comparison.png` | `/admin/reports/branches` | Branch comparison | 1440×900 | `4fc89f86e23ae20a878e7d42d2af1b6b203d74c0554a433afb0f5cd643351eed` | PASS |
| `34-admin-sales-reports.png` | `/admin/reports/sales` | Sales report (filtered) | 1440×900 | `371edcdc000f961e9f552276017ab78e753528f4b5daac8cf5d8eae909ebc599` | PASS |
| `35-admin-product-performance.png` | `/admin/reports/products` | Product performance | 1440×900 | `777ae8fcc439149da7458c4674e2828be5ecd0c97e0c00341cda35ec443b4846` | PASS |
| `36-admin-shift-report.png` | `/admin/reports/shifts` | Shift cash report | 1440×900 | `e1a8da9410d1ab0178e4fe80557d792ed03d6586a0836ea4e43fe9111278257d` | PASS |
| `37-admin-branches.png` | `/admin/operations/branches` | Branches | 1440×900 | `3aa2b83ba12aaa086b9c7d565d224f765d1b02439c41ea1509cd701f755e5475` | PASS |
| `38-admin-sales-points.png` | `/admin/operations/sales-points` | Sales points | 1440×900 | `b267b636f670bea7a011cbae22f1e731c8221ab21a9d797934f343c4bab0872f` | PASS |
| `39-admin-terminals.png` | `/admin/operations/terminals` | Terminals | 1440×900 | `490d94285271c16ef004b5afee0c0e58a4e3833cba01879cca32b5d8acbf1f26` | PASS |
| `40-admin-staff-roles.png` | `/admin/operations/employees` | Staff and roles | 1440×900 | `31f84e337672b9097b43a25db1d850e9a92d86290fc72fc0e2f6838c691e036e` | PASS |
| `41-admin-menu.png` | `/admin/catalogue/menu` | Menu | 1440×900 | `170e0fd1aa68b2a60dbf7640d6f3d3ef47e0a46a8379f1b47570804d2452dda7` | PASS |
| `42-admin-product-editor.png` | `/admin/catalogue/menu/latte` | Product editor | 1440×900 | `f53c97424cde2430799bf7274f7687229f96ed8d1af74503365ebee8b3db721a` | PASS |
| `43-admin-modifiers.png` | `/admin/catalogue/variants` | Modifiers / variants | 1440×900 | `796494a65e333fbb2ed05912c846adad5b153e0da3b64ba5a0512196d4aeea2c` | PASS |
| `44-admin-rewards.png` | `/admin/rewards/loyalty` | Loyalty rewards | 1440×900 | `1ced58bdaa441f9c3fbda5abeb061b8407ba2c96af1304ef8cf9eb8d226334be` | PASS |
| `45-admin-campaigns.png` | `/admin/rewards/campaigns` | Campaigns | 1440×900 | `4f5f1fbc0702feabd1e4958c3027c287f397aa52429b235cd8a95f2852f6aff9` | PASS |
| `46-admin-ad-publishing.png` | `/admin/rewards/ads` | Ad publishing | 1440×900 | `d5392ab0c92d6fd89594b46f6e439b826f9acdbb0f4597829505e76489789091` | PASS |
| `47-admin-members.png` | `/admin/reports/members` | Members | 1440×900 | `653a10855c443baf657c2e574997cb104f0e4649785d4c748cbc24ed42464776` | PASS |
| `48-admin-audit-log.png` | `/admin/system/audit` | Audit log | 1440×900 | `b3c17f14cf99dc9ae9cf70c6df68bc8d18497a54c4d05b85eb4c549b0d145774` | PASS |
| `49-admin-settings.png` | `/admin/system/settings` | Settings | 1440×900 | `fe85409eadfd947758f4695017948017f716f2d3d051112dcc43a3ed463084d3` | PASS |

## Duplicate-hash result

PASS — 38 unique SHA-256 hashes for 38 successful captures.

Failed or skipped: 0
