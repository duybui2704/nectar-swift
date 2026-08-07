# Product Detail — API priority & loading

## Phased load

| Phase | APIs | When | Why |
|-------|------|------|-----|
| **Critical (first paint)** | `product/{id}`, `gallery/{id}`, `variant/{id}?format=1` | Await in parallel before meaningful UI | Title/price/seller, hero carousel, color/type/style/size/print |
| **Secondary (background)** | `bulk-price`, `related`, `recommendation-keyword`, `bought-together`, `color-guide` | Fire-and-forget `Task` after critical | Below-fold rails, quantity hint, FBT; must not block scroll |

```
open PDP
  └─ TaskGroup critical  ──► paint gallery + info + variants + sticky CTA
  └─ Task (detached) secondary ──► fill rails / FBT / bulk hint as they arrive
```

## UI states

| Phase | UI |
|-------|----|
| `loading` | Gallery skeleton + shimmer lines; **no** Add to Cart footer |
| `failed` | Centered message + Retry CTA + back; **no** footer; tab bar hidden |
| `ready` | Full PDP + sticky footer; floating tab bar hidden (navigation depth) |

Tab bar: `MainShellView` calls `TabBarVisibility.setNavigationHidden` when the selected tab’s path is non-empty — prevents footer red bleed through the glass tab bar.

## Endpoint map

| UI block | Endpoint |
|----------|----------|
| Title, price, stock, seller, rating | `GET product/{id}` |
| Hero carousel | `GET gallery/{id}` |
| Color / type / style / size / print | `GET variant/{id}?format=1` |
| Quantity subtext | `GET product/bulk-price/{id}` |
| Style/size guide (prefetch) | `GET product/color-guide/{id}` |
| “Design also available on” | `GET product/related/{id}` |
| “You might love these” | `GET product/recommendation-keyword/{id}` |
| Frequently bought together | `GET bought-together/find?productId=&limit=3` |

## Code layout

```
Features/Product/
├── Domain/   ProductDetailModels, ProductDetailProviding
├── Data/     ProductDTOMapper, ProductDetailRepository
└── Presentation/
    ├── ProductDetailView + ViewModel
    └── Components/…
```

ViewModel → `ProductDetailProviding` → `ProductDetailRepository` → `PrintervalAPI` (`.variant`).
