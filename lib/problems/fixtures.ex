defmodule Problems.Fixtures do
  @moduledoc """
  Hardcoded problems used before the Ecto schema exists.
  Temporary: this module is deleted in phase 2, when `mix problems.import`
  starts loading problems from markdown files into Postgres.
  """

  def list_problems do
    [
      %{
        slug: "szufladkowa-51-liczb",
        subject: :math,
        title: "Pięćdziesiąt jeden liczb ze stu",
        difficulty: 3,
        source: "Klasyka olimpijska (Erdős)",
        topics: ["teoria-liczb", "zasada-szufladkowa"],
        body: ~S"""
        Ze zbioru $\{1, 2, \ldots, 100\}$ wybieramy dowolne $51$ liczb.

        Wykaż, że wśród wybranych liczb istnieją dwie takie, że jedna z nich dzieli drugą.

        Czy teza pozostaje prawdziwa, jeśli wybierzemy tylko $50$ liczb?
        """,
        hint: ~S"""
        Każdą liczbę naturalną można jednoznacznie zapisać jako $2^a \cdot q$, gdzie $q$ jest
        nieparzyste. Ile różnych wartości może przyjąć $q$ dla liczb ze zbioru $\{1, \ldots, 100\}$?
        """,
        solution: ~S"""
        Każdą liczbę $m \in \{1, \ldots, 100\}$ zapisujemy jednoznacznie w postaci
        $$m = 2^{a} \cdot q, \qquad a \geqslant 0, \quad q \text{ nieparzyste}.$$

        Wartość $q$ (część nieparzysta) należy do zbioru $\{1, 3, 5, \ldots, 99\}$, który ma
        dokładnie $50$ elementów. Wybieramy $51$ liczb, więc z zasady szufladkowej dwie z nich
        mają tę samą część nieparzystą:
        $$m_1 = 2^{a} q, \qquad m_2 = 2^{b} q, \qquad a < b.$$

        Wtedy $m_2 / m_1 = 2^{b-a}$ jest liczbą całkowitą, czyli $m_1 \mid m_2$.

        Dla $50$ liczb teza jest fałszywa: zbiór $\{51, 52, \ldots, 100\}$ ma $50$ elementów,
        a iloraz dwóch różnych jego elementów jest mniejszy od $2$, więc żaden nie dzieli innego.
        """
      },
      %{
        slug: "przewracajacy-sie-pret",
        subject: :physics,
        title: "Przewracający się pręt",
        difficulty: 3,
        source: "Mechanika bryły sztywnej, zadanie klasyczne",
        topics: ["mechanika", "bryla-sztywna", "zachowanie-energii"],
        body: ~S"""
        Jednorodny pręt o masie $m$ i długości $L$ stoi pionowo na szorstkiej poziomej podłodze.
        Pręt zostaje nieznacznie wychylony i zaczyna się przewracać, przy czym jego dolny koniec
        nie ślizga się przez cały czas ruchu.

        Wyznacz prędkość górnego końca pręta w chwili, gdy uderza on o podłogę.

        Oblicz wartość liczbową dla $L = 1{,}0$ m i $g = 9{,}81\ \mathrm{m/s^2}$.
        """,
        hint: ~S"""
        Ruch jest obrotem wokół nieruchomej osi przechodzącej przez dolny koniec. Moment
        bezwładności pręta względem końca to $I = \tfrac{1}{3} m L^2$. Jak zmienia się wysokość
        środka masy?
        """,
        solution: ~S"""
        Środek masy pręta opada z wysokości $L/2$ do zera, więc energia potencjalna maleje o
        $$\Delta E_p = mg\frac{L}{2}.$$

        Cała ta energia zamienia się w energię kinetyczną obrotu wokół dolnego końca:
        $$mg\frac{L}{2} = \frac{1}{2} I \omega^2 = \frac{1}{2} \cdot \frac{mL^2}{3} \cdot \omega^2.$$

        Stąd
        $$\omega = \sqrt{\frac{3g}{L}}, \qquad v = \omega L = \sqrt{3gL}.$$

        Dla $L = 1{,}0$ m otrzymujemy $v = \sqrt{3 \cdot 9{,}81 \cdot 1{,}0} \approx 5{,}4\ \mathrm{m/s}$.

        Uwaga: wynik jest większy od prędkości swobodnego spadku z wysokości $L$, czyli
        $\sqrt{2gL} \approx 4{,}4$ m/s. Nie ma w tym sprzeczności — dolna część pręta opada
        wolniej i „przekazuje" energię górnemu końcowi.
        """
      },
      %{
        slug: "oo-czy-or",
        subject: :quant,
        title: "Orzeł-orzeł czy orzeł-reszka",
        difficulty: 4,
        source: "Klasyczne pytanie rekrutacyjne (prop trading)",
        topics: ["prawdopodobienstwo", "wartosc-oczekiwana", "lancuchy-markowa"],
        body: ~S"""
        Rzucamy uczciwą monetą tak długo, aż po raz pierwszy pojawi się zadana sekwencja
        dwóch kolejnych wyników.

        Ile średnio rzutów potrzeba, aby zobaczyć sekwencję $OO$ (dwa orły pod rząd)?
        Ile średnio rzutów potrzeba, aby zobaczyć sekwencję $OR$ (orzeł, potem reszka)?

        Obie sekwencje mają prawdopodobieństwo $1/4$ w dwóch ustalonych rzutach. Czy odpowiedzi
        są równe? Jeśli nie, wyjaśnij, skąd bierze się różnica.
        """,
        hint: ~S"""
        Rozpatrz stan „ostatni rzut był orłem". Co się dzieje, gdy w tym stanie wypadnie orzeł —
        w przypadku sekwencji $OR$, a co w przypadku $OO$?
        """,
        solution: ~S"""
        Niech $a$ oznacza oczekiwaną liczbę rzutów od początku, a $b$ oczekiwaną liczbę rzutów
        w stanie „ostatni rzut był orłem".

        **Sekwencja $OR$.** W stanie $b$ reszka kończy grę, orzeł pozostawia nas w tym samym
        stanie:
        $$a = 1 + \tfrac{1}{2} a + \tfrac{1}{2} b, \qquad b = 1 + \tfrac{1}{2} b.$$
        Stąd $b = 2$ oraz $a = 4$.

        **Sekwencja $OO$.** W stanie $b$ orzeł kończy grę, ale reszka **cofa nas do początku**:
        $$a = 1 + \tfrac{1}{2} a + \tfrac{1}{2} b, \qquad b = 1 + \tfrac{1}{2} a.$$
        Podstawiając drugie równanie do pierwszego: $a = 2 + b = 3 + \tfrac{1}{2} a$, czyli
        $a = 6$.

        Odpowiedź: $6$ rzutów dla $OO$ i $4$ dla $OR$.

        Źródło różnicy: sekwencja $OO$ może „zniszczyć sama siebie". Nieudana próba (orzeł,
        potem reszka) traci cały postęp, bo reszka nie jest prefiksem $OO$. Przy $OR$ nieudana
        próba (orzeł, potem orzeł) zachowuje postęp — nadal mamy świeżego orła, więc wciąż
        jesteśmy o jeden rzut od sukcesu. Mówiąc inaczej: sekwencje nakładające się na siebie
        czekają dłużej, mimo identycznego prawdopodobieństwa w pojedynczym oknie dwóch rzutów.
        """
      }
    ]
  end
end
