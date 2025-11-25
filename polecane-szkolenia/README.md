# Polecane szkolenia

- [Polecane szkolenia](#polecane-szkolenia)
  - [Linux - podstawy](#linux---podstawy)
  - [Git](#git)
  - [Docker](#docker)
  - [Ansible](#ansible)
  - [Terraform](#terraform)
  - [CI/CD w oparciu o GitHub Actions](#cicd-w-oparciu-o-github-actions)

Jeśli po przejściu wszystkich stepów nadal czujesz niedosyt to polecam zajrzeć do poniższych szkoleń. Na pewno uzupełnią lub rozwiną twoją wiedzę.

Część z nich jest płatna i dostępna platformie udemy. Kupujcie tylko kiedy jest promocja, która trwa tam w zasadzie non stop :) da się wszystko dorwać między 29 a 59 zł. Czasem warto włożyć kilka groszy w swój rozwój.

Druga część jest dostępna YouTube za darmo.

Pamiętaj, że najważniejsza jest praktyka i podejście **GTD (Get things Done)**. Nie musisz mieć ładnie napisanego kodu, na początku najważniejsze jest to, żeby wykonał zadanie. Później kiedy poznasz kolejne koncepcje i rozwiązania przyjdzie czas na **refactoring**.

## Linux - podstawy

Użyj WSL2 lub postaw osobną wirtualną maszynę na VirtualBoxie i przjedź przez na przykład takie wprowadzenie: https://www.youtube.com/watch?v=v392lEyM29A

Spróbuj później postawić prosty serwer WWW z wykorzystaniem nginx lub apache, a na nim zainstaluj wordpressa. Dodaj do tego jeszcze bazę danych i przejdź krok po kroku przez jej instalację i inicjalizację.

## Git

Bardzo fajne szkolenie z gita, które pozwala się zapoznać z tym narzędziem od podstaw: https://www.udemy.com/course/git-and-github-bootcamp/

## Docker

Ekstra szkolenie wprowadzające do dockera, później jest też rozwinięta koncepcja używania kontenerów w docker swarm oraz kubernetes (to już dla bardziej zaawansowanych): https://www.udemy.com/course/docker-mastery/

## Ansible

Z ansible mam problem, nigdy nie znalazłem dobrego kursu i szczerze nie mogę nic polecić, ale...

Jeff Geerling, gość który zrobił multum roli do ansible używanych przez miliony administratorów, ma całą serię na youtube o Ansible: https://www.youtube.com/watch?v=goclfp6a2IQ&list=PL2_OBreMn7FqZkvMYt6ATmgC0KAGGJNAN myślę, że warto sprawdzić :)

No i najważniejsze, po prostu zacznijcie to robić, a pytania przyjdą do was same i zaczniecie odkrywać powoli świat automatyzacji konfiguracji serwerów.

## Terraform

Terraform na pewno jest dla bardziej zaawansowanych administratorów, którzy rozumieją czym jest chmura i jak z niej korzystać.

Jest pełno kursów na youtube, które pokazują co i jak zrobić na np. Azure, GCP czy AWS.

Prawda jest taka, że jak zrozumiecie koncepcję idącą za terraformem i to gdzie oraz jak przechowywać pliki `tfstate` to praktycznie wszystko da się znaleźć w ich dokumentacji i zadając odpowiednie pytania wujkowi Google.

## CI/CD w oparciu o GitHub Actions

Poszerzenie wiedzy na ten temat wymaga od nas średniozaawanasowanej wiedzy czym jest `git`, a zwłaszcza czym są branche i `git flow` oraz `github flow`, czyli dwa najpopularniejsze modele zarządzania repozytorium kodu. Bez tego ciężko będzie nam zrozumieć koncepcje idące za CI/CD (Continous Integration & Continous Delivery).

Wprowadzenie czym w ogóle jest GitHub Actions: https://www.youtube.com/watch?v=R8_veQiYBjI

Średniozaawansowany kurs, ale są też poruszane podstawowe koncepcje: https://www.youtube.com/watch?v=Xwpi0ITkL3U

Polecam tutaj na początek zabawę z puszczaniem playbooków ansible przy użyciu github actions, można się wiele nauczyć. Najlepiej takich, które uruchomią nam na przykład wordpressa, albo jeśli jesteś programistą, to twój kod w kontenerze.
