#import "@preview/touying:0.7.4": *
#import "@preview/cetz:0.5.1"
#import "@preview/cetz-plot:0.1.4"
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import themes.simple: *

#show: simple-theme.with(aspect-ratio: "16-9")

#set page(paper: "presentation-16-9", fill: teal.lighten(90%))
#set text(size: 25pt, font: "Noto Sans")
#let cetz-canvas = touying-reduce.with(cetz)

#title-slide[
  = Nawigacja Rowerowa
  #v(2em)

  Stanisław Fiedler #h(2em)
  Michał Łatka 

  #v(2em)
  _Poznań 2026_
]

== Cel i przeznaczenie aplikacji
Celem projektu było stworzenie aplikacji mobilnej wspomagającej nawigację rowerową.

Jednym z głównych założeń projektu było preferowanie infrastruktury przyjaznej rowerzystom.

== Główne funkcje
Aplikacja umożliwia:
- wyznaczanie tras rowerowych pomiędzy wskazanymi punktami
- prezentowanie alternatywnych wariantów przejazdu
- prowadzenie użytkownika po wybranej trasie w czasie rzeczywistym

== Ekrany
#box(image("./img/1.jpg",height: 80%), clip: true, inset: (bottom: -33pt))
#h(1em)
#box(image("./img/2.jpg",height: 80%), clip: true, inset: (bottom: -33pt))
#h(1em)
#box(image("./img/3.jpg",height: 80%), clip: true, inset: (bottom: -33pt))
#h(1em)
#box(image("./img/4.jpg",height: 80%), clip: true, inset: (bottom: -33pt))
#h(1em)


== Role członków zespołu i podział obowiązków
#columns(2, gutter: 10pt)[
  Stanisław 
  - logika aplikacji
  - uruchomienie usług OSRM i Pocketbase

  #colbreak()
  Michał
  - przygotowanie ekranów 
  - nawigacja między ekranami
]

== Zastosowane narzędzia i technologie z uzasadnieniem tych wyborów
- Flutter
  - wieloplatformowość
  - prostota budowy aplikacji

- Pocketbase
  - Jedno rozwiązanie łączące bazę danych oraz logowanie
  - alternatywa dla Firebase Google 
  - OpenSource, Self Hosted

- OSRM (Open Source Routing Machine)
  - możliwość rozbudowanego definiowania preferencji dla trasy
  - alternatywa dla Map Google 
  - OpenSource, Self Hosted

== Stopień realizacji wymagań funkcjonalnych i niefunkcjonalnych
Jedynym niezaimplementowany wymaganiem funkcjonalnym jest brak wskazówek podczas nawigacji.

Zaimplementowane funkcje spełniają wymagania niefunkcjonalne.

== Architektura systemu 

  #place(center+ horizon, diagram(
    node((-1,0), $"serwer:"$),
    node((-1,1), $"klient:"$),

    node((0,0), $"OSRM"$),
    node((1,0), $"Pocketbase"$),
    node((0.5,1), $"Aplikacja"$),

    edge((0,0), (0.5,1), "<->"),
    edge((1,0), (0.5,1), "<->")
))


== Diagram przepływu sterowania pomiędzy składowymi aplikacji
#place(center+ horizon, diagram(
    node((0,0), $"Wybór adresów"$),
    node((0,1), $"Logowanie"$),
    node((1,0), $"Wybór trasy"$),
    node((2,0), $"Nawigacja"$),

    edge((0,0), (0,1), "<->"),
    edge((0,0), (1,0), "<->"),
    edge((1,0), (2,0), "<->")
))


== Problemy napotkane w trakcie realizacji

Pokazywanie następnego kroku kroku okazało się być bardzo trudne do zaimplementowania.

Dlatego podczas nawigacji nie wyświetlają się informacje:
#align(center,box(fill: gray, inset: 20pt, radius: 5pt, [za 10m skręć w prawo]))

== Potencjalne kierunki dalszego rozwoju aplikacji

- Można zaimplementować zagadnienie z poprzedniego slajdu.

- Aplikacja podczas wyznaczania trasy mogłaby też brać pod uwagę preferencje użytkownika.

= Dziękujemy
