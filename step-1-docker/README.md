# Step 1 - Docker 101

- [Step 1 - Docker 101](#step-1---docker-101)
  - [Docker](#docker)
  - [Proste uruchamianie kontenerów - docker run](#proste-uruchamianie-kontenerów---docker-run)
    - [Bind](#bind)
  - [Deployment multi-kontenerowego środowiska - docker compose](#deployment-multi-kontenerowego-środowiska---docker-compose)
    - [Wolumeny](#wolumeny)
    - [Sprzątanie](#sprzątanie)
  - [Przydatne komendy](#przydatne-komendy)
    - [docker](#docker-1)
    - [compose](#compose)
    - [logi](#logi)

Będąc w głownym folderze repozytorium przejdź do folderu: `cd step-1-docker`.

## Docker

Docker to narzędzie, które umożliwia **konteneryzację** — sposób uruchamiania aplikacji w lekkich, odizolowanych środowiskach zwanych **kontenerami**.

Jeśli znasz maszyny wirtualne, to najprościej myśleć o kontenerach jako o „lżejszych VM-kach”. Kontenery nie mają własnego systemu operacyjnego — współdzielą jądro hosta, a izolacja działa na poziomie procesów. Dzięki temu:

- uruchamiają się bardzo szybko,
- zajmują mało zasobów,
- są powtarzalne - uruchomienie kontenera w innym systemie da taki sam rezultat.

Docker pozwala pakować aplikacje wraz z ich zależnościami do obrazu, który można potem uruchamiać na dowolnym serwerze z Dockerem, niezależnie od konfiguracji hosta.

Konteneryzacja upraszcza wdrażanie, skalowanie i utrzymanie aplikacji — zamiast martwić się o różnice między środowiskami, po prostu uruchamiasz ten sam kontener na środowisku testowym i produkcyjnym.

## Proste uruchamianie kontenerów - docker run

Uruchom **Docker Desktop** i sprawdź działanie dockera wykonując komendę:

```bash
$ docker run --rm hello-world:latest
Hello from Docker!
```

Jeśli został ściągnięty obraz i dostałeś komunikat **Hello from Docker!** to wszystko jest w porządku.

Postawmy teraz prosty serwer WWW.

```bash
docker run nginx:latest
```

Na pewno zauważyłeś, że zostałeś "uwięziony "w kontenerze, a po wywołaniu w przeglądarce pod http://localhost nie wyświetla się nic.
Naprawmy to.

Wciśnij `Ctrl+C`, aby się uwolnić i wyświetl wszystkie kontenery

```bash
$ docker ps -a
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS                     PORTS     NAMES
e6143d0d1c38   nginx:latest   "/docker-entrypoint.…"   7 minutes ago   Exited (0) 3 minutes ago             eager_lamarr
```

Zauważ, że nazwa jest losowa, a kontener został zatrzymany. Usuń teraz kontener używając jego nazwy `docker rm -f <nazwa_kontenera>`s.

Uruchomimy teraz kontener, tak żebyśmy w nim nie utknęli, nadamy mu nazwę i wystawimy, jego port tak abyśmy mogli się z nim połączyć.

```bash
docker run -d -p 80:80 --name nginx nginx:latest

# -d - to detach, dzięki niemu nie utkniemy w kontenerze
# -p - to publish, czyli jaki port chcemy wystawić publicznie. Pierwsza cyfra to port naszego komputera, a druga to port w kontenerze.
# --name - nie trzeba tłumaczyć :)
# Jeśli potrzebujesz zobaczyć wszystkie opcje dla komendy "docker run" to po prostu wpisz docker run --help
```

Przejdź do http://localhost i zobacz czy widzisz witrynę domyślną nginx. Jeśli wszystko jest OK usuń kontener.

### Bind

Dodajmy teraz jakąś naszą prostą stronkę. Użyjemy do tego bindingu, czyli udostępnimy lokalny plik lub folder, bezpośrednio do kontenera.

```bash
echo 'ITLab ZHP' > index.html
docker run -d -p 80:80 --name nginx -v ./index.html:/usr/share/nginx/html/index.html nginx:latest
```

Teraz po odświeżeniu (`Ctrl+F5`) stronki powinniście zobaczyć tekst **ITLab ZHP**.
Spróbuj teraz zmodyfikować plik komendą `echo` i przeładować stronę.

Usuń kontener i plik index.html.

```bash
docker rm -f nginx
rm -f index.html
```

## Deployment multi-kontenerowego środowiska - docker compose

Pewnie zastanawiasz się, czy nie da się całej tej operacji jakoś uprościć jeśli mamy do uruchomienia więcej kontenerów.
Postawmy zatem naszego ukochanego Wordpressa, ale na kontenerach. Wykorzystamy w tym celu specjalny plik, w którym zadeklarujemy nasze całe środowisko wordpressowe i jedną komendą będziemy mogli je uruchamiać, zatrzymywać i usuwać.

Przejrzyj plik `docker-compose.yml` i wykonaj komendę

```bash
docker compose up -d # bez -d znowu zostalibyśmy uwięzieni w kontenerach :)
```

Docker z automatu użyje pliku docker-compose.yml i postawi nasz zdefiniowany tam deployment. Jeśli twój plik nazywa się inaczej użyj argumentu `-f nazwa-pliku.yml` zaraz przed komendą `up` > `docker compose -f nazwa-pliku.yml up -d`.

Teraz przechodząc na http://localhost ukaże nam się strona wordpressa, przejdź szybko przez instalację i zaloguj się na admina.

Dobra to teraz usuńmy cały nasz deployment i uruchommy go ponownie.

```bash
docker compose rm -sf
docker compose up -d
```

Ponownie przejdź na http://localhost, jaka jest różnica?

### Wolumeny

Kontenery z definicji są efemeryczne, to znaczy że jeśli zostaną usunięte to tracicie wszystkie dane, które na nich były. Żeby temu zapobiec musimy użyć wolumenów.

Odkomentuj linijki w `docker-compose.yml`, w tym celu zaznacz je i kliknij `Ctrl + /` (ten skrót służy do zakomentowania i odkomentowania linijek w większości IDE) lub usuń `#` i spację po hashtagu:

```yml
    # volumes:
    #   - wp_data:/var/www/html

........

    # volumes:
    #   - db_data:/var/lib/mysql

........

# volumes:
#   wp_data:
#   db_data:
```

i ponownie wykonaj komendę `docker compose up -d`. Cały deployment zostanie zaktualizowany automatycznie.

Przejdź instalację wordpressa ponownie, usuń deployment i utwórz go ponownie. Czy tym razem dane zostały zachowane?

Możesz też wyświetlić wolumeny po usunięciu deploymentu:

```bash
$ docker volume ls
DRIVER    VOLUME NAME
local     step-1_db_data
local     step-1_wp_data
```

Zróbmy jeszcze upgrade MySQL z wersji 5.7 do wersji 8.0.

> [!WARNING]
> To nie jest rekomendowana droga wykonywania upgrade'ów baz danych.
> Za każdym razem powinieneś potwierdzić, że ustawienia serwera i tabeli bazy danych są zgodne z wersją do której się upgrade'ujesz.
> Powinieneś także sprawdzić czy przeskok z danej wersji do docelowej to rekomendowany **upgrade path**.
> Zaraz przed powinieneś także zatrzymać kontenery aplikacyjne i utworzyć konsystentny dump bazy danych. Konsystentny, czyli taki który nie zawiera w sobie niedokończonych transakcji bazy danych.

W linijce z `image: mysql:5.7` zmień wartość 5.7 na 8.0 i wykonaj redeployment kontenerów, komendę już znasz.

### Sprzątanie

Pora po sobie posprzątać i przejść do step-2:

```bash
docker compose rm -sf
docker volume prune -a -f && docker image prune -a -f && docker network prune -f
```

## Przydatne komendy

### docker

```bash
docker ps -a # Wyświetla wszystkie działające i niedziałające kontenery

docker stop <nazwa_kontenera> # Zatrzymuje działający kontener
docker start <nazwa_kontenera> # Uruchamia zatrzymany kontener
docker restart <nazwa_kontenera> # Restartuje kontener

docker inspect <nazwa_kontenera> # Wyświetla nam całą szczegółową konfigurację kontenera

docker rm <nazwa_kontenera> # Usuwa zatrzymany kontener
docker rm -f <nazwa_kontenera # Zatrzymuje i usuwa kontener

docker image ls # Wyświetla pobrane obrazy kontenerów
docker image prune -a -f # Usuwa wszystkie nieprzypisane obrazy

docker network ls # Wyświetla wszystkie sieci w dockerze
docker network prune -f # Usuwa wszystkie nieprzypisane sieci

docker volume ls # Wyświetla wszystkie wolumeny
docker volume prune -a -f # Usuwa wszystkie nieprzypisane wolumeny

docker volume prune -a -f && docker image prune -a -f && docker network prune -f # Usuwa wszystkie nieprzypisane elementy (sieci, obrazy, wolumeny)

docker exec -ti <nazwa_kontenera> bash # pozwala nam wejść do kontenera jakby był to osobny system. Czasem zamiast bash musimy wpisać 'sh', zależy to od użytego kontenera

docker --help # Pokaż wszystkie opcje
docker <komenda> --help # Pokaż wszystkie opcje dla konkretnej komendy
```

### compose

```bash
docker compose up -d # Uruchom całe środowisko, a po zmianie pliku, zaktualizuj

docker compose stop # Zatrzymaj wszystkie kontenery
docker compose restart # Zrestartuj kontenery
docker compose start # Uruchom kontenery, jeśli zostały zatrzymane

docker compose rm -sf # Zatrzymaj i usuń wszystkie kontenery
```

### logi

```bash
docker logs <nazwa_kontenera> # Wyświetlisz wszystkie logi, które kontener z siebie wyrzucił
docker logs -f <nazwa_kontenera> # Wyświetlasz logi, ale cały czas są one odświeżane. Żeby z nich wyjść użyj Ctrl + C
docker logs -n <liczba> <nazwa_kontenera> # Wyświetlisz X ostatnich logów
```
