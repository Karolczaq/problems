---
# Format pliku zadania. Nazwa pliku (bez .md) to slug: małe litery, cyfry, myślniki.
# Katalogi nie mają znaczenia dla programu — układaj pliki, jak chcesz.
title: "Suma kolejnych liczb nieparzystych"  # opcjonalny; brak → source → nazwa pliku
subject: math                   # wymagany; małe litery, cyfry, myślniki
difficulty: 1                   # wymagany; 1..5
topics: [algebra, indukcja]     # opcjonalne; tagi tematyczne
labels: [przyklad]              # opcjonalne; etykiety organizacyjne
source: "Przykład formatu"      # opcjonalne
year: 2026                      # opcjonalne
answer: "n^2"                   # opcjonalne; w cudzysłowie, żeby YAML nie zrobił z tego liczby
---

Udowodnij, że suma $n$ pierwszych liczb nieparzystych jest równa $n^2$:
$$1 + 3 + 5 + \dots + (2n - 1) = n^2.$$

<!-- hint -->
Indukcja po $n$: co się dzieje z sumą, gdy dopisujemy kolejny składnik $2n + 1$?

<!-- solution -->
Dla $n = 1$ mamy $1 = 1^2$. Jeśli $1 + 3 + \dots + (2n - 1) = n^2$, to po dodaniu $2n + 1$
otrzymujemy $n^2 + 2n + 1 = (n + 1)^2$, co kończy krok indukcyjny.
