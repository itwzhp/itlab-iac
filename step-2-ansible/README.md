# Step 1 - Ansible 101

- [Step 1 - Ansible 101](#step-1---ansible-101)
  - [Ansible](#ansible)
  - [Playbooks](#playbooks)
    - [Proste playbooki](#proste-playbooki)
    - [Templatki](#templatki)
    - [Warunki i zmienne w playbookach](#warunki-i-zmienne-w-playbookach)
    - [Tagi](#tagi)
    - [Deployment kontenerów dockera z ansible](#deployment-kontenerów-dockera-z-ansible)
    - [Inventory](#inventory)
      - [Zmienne w plikach](#zmienne-w-plikach)
    - [Struktura folderów](#struktura-folderów)
    - [Role](#role)
      - [Ansible galaxy - czyli kolekcje i role udostępnione przez społeczność](#ansible-galaxy---czyli-kolekcje-i-role-udostępnione-przez-społeczność)

Będąc w głownym folderze repozytorium przejdź do folderu: `cd step-2-ansible/playbooks`.

## Ansible

Ansible to jedno z narzędzi, które pozwala na zdalne zarządzanie i automatyzacje wdrożeń na jednym lub grupie serwerów.

Jest przydatne kiedy musimy każdy z serwerów zainicjalizować dokładnie w taki sam sposób (instalujemy te same aplikacje, monitoring itd..). Minusem jest to, że ansible controller (w tym przypadku nasz laptop) musi posiadać możliwość połączenia się z serwerem przez SSH. Istnieją inne systemy automatyzacji, które nie potrzebują takiego połączenia. Wtedy to serwery docelowe łączą się z kontrolerem i utrzymują stale to połączenie.

## Playbooks

Można uruchomić ansible zwykłą komendą, podając wszystkie parametry, np.: `ansible localhost -m apt -a "name=htop state=present" -b --ask-become-pass`, która zainstaluje na naszym lokalnym serwerze program o nazwie htop.Zrobi to przy użyciu modułu `apt`, czyli modułu na linuxach debianopodobnych (Debian, Ubuntu), który pozwala na instalację programów.

O wiele lepszym wyjściem będzie użycie playbooków, czyli całego spisu akcji, które mają się zadziać na docelowych serwerach.

### Proste playbooki

Otwórz plik `install-apps.yml` i przeanalizuj go. Jak myślisz co zostanie wykonane i jakie moduły zostały użyte?

Uruchom teraz tego playbook dwa razy komendą:

```bash
ansible-playbook install-apps.yml --ask-become-pass # --ask-become-pass pozwala nam na podanie hasła roota (super usera)
```

Jaka jest różnica między pierwszym a drugim razem?

Zakomentuj teraz w module instalacji aplikacji linijkę `state: present` i odkomentuj `state: absent`. Zmień także `Hello World!` na coś zupełnie innego i puść playbooka jeszcze raz.

### Templatki

Jest jeden problem, co jeśli chcemy aby plik `index.html`, był tworzony z jakiegoś wzoru? Przecież nie będziemy do playbooka wpisywać całej zawartości jakiejś wielkiej strony bo stałoby się to kompletnie nieczytelne.

W tym celu wykorzystujemy templatki, które muszą być napisane w specjalnym języku `Jinja`. W folderze `templates`, notabene z niego ansible automatycznie bierze templatki, mamy plik `index.html.j2`, każda zmienna której będziemy chcieli użyć ma specjalny format `{{ nazwa }}`, dzięki temu ansible jest w stanie ją podmienić w zależności od jej wartości. Jinja pozwala także na instrukcje warunkowe, pętle i wiele innych instrukcji. Zainteresowanych odsyłam do oficjalnej dokumentacji: https://jinja.palletsprojects.com/en/stable/templates/

Są tam także specjalne zmienne z prefixem `ansible_`, które pobieramy z serwera dzięki linijce `gather_facts: yes` w naszym playbooku. Więcej o faktach pobieranych z serwera: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_vars_facts.html

Musimy także podać naszą zmienna `my_variable`.

Wykonajmy więc komendą razem ze spacjalnym parameterem `--estra-vars`:

```bash
ansible-playbook templates.yml --ask-become-pass --extra-vars "my_variable='Ala ma kota'"
```

> [!NOTE]
> Zmienne typu string ze spacjami muszą być umieszczone w cudzysłowie, a sam nasz tekst jeszcze między apostrofami.
> Jeśl byłoby to jedno słowo, lub liczba to można użyć po prostu: `--extra-vars my_variable=1234`

Sprawdź teraz plik `index.html` w folderze playbooks, powinien tam być twój tekst, razem z informacją o nazwie twojego serwera i edycji linuxa, której używasz.

### Warunki i zmienne w playbookach

Na pewno zauważyłeś już podczas wykonywania playbooka `install-apps.yml` opcję `when:`. When to instrukcja warunkowa (conditional) dla danego zadania. Możesz mieć jedną lub możesz mieć wiele takich instrukcji, dostępne wtedy są operatory logiczne, takie jak `and`, `or`, `not`. Dokładnie takie same jak w poznanej już `Jinjy`.

Operator or:

```yml
tasks:
  - name: Shut down CentOS 6 and Debian 7 systems
    ansible.builtin.command: /sbin/shutdown -t now
    when: (ansible_facts['distribution'] == "CentOS" and ansible_facts['distribution_major_version'] == "6") or
          (ansible_facts['distribution'] == "Debian" and ansible_facts['distribution_major_version'] == "7")
```

Operator and:

```yml
tasks:
  - name: Shut down CentOS 6 systems
    ansible.builtin.command: /sbin/shutdown -t now
    when:
      - ansible_facts['distribution'] == "CentOS"
      - ansible_facts['distribution_major_version'] == "6"
```

Więcej na temat conditionals: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_conditionals.html

Przeanalizuj playbook `conditions.yml`, jak myślisz co się stanie, kiedy zdefiniujemy zmienną `my_variable`, a co jak tego nie zrobimy?

Spróbuj sam stworzyć odpowiednią komendę i puścić tego playbooka z i bez zmiennej.

### Tagi

Czasem chcemy aby playbook nie wykonywał wszystkich operacji, ale chcemy żeby tylko niektóre taski zostały wykonane.

Wtedy w tasku definiujemy tagi:

```yml
    - name: Install monitoring tools
      ansible.builtin.apt:
        name:
          - htop
          - atop
        state: present # state present oznacza, że pakiety mają być zainstalowane. Jeśli już są zainstalowane, nic się nie stanie.
        # state: absent # state absent oznacza, że pakiety mają być odinstalowane. Jeśli nie są zainstalowane, nic się nie stanie.
      tags:
        - install_monitoring_tools
        - packages
```

Przeanalizuj playbooka `install-apps-with-tags.yml`, jakie mamy dostępne tagi?

Czasem playbooki są ogromne i wtedy mamy taką opcję jak `--list-tags`, wykonaj komendę:

```bash
ansible-playbook install-apps-with-tags.yml --list-tags
```

Zauważ, że wyświetlił się także tag o nazwie `always`, to oznacza że dany task zawsze będzie wykonany, niezależnie od tego co zrobimy.

Jest także tag `never`, ten task wykona się tylko wtedy kiedy poprosimy ansible o wykonanie tagu `remove_monitoring_tools`.

Użyjmy teraz jednego z tagów z prefixem `install_`

```bash
ansible-playbook install-apps-with-tags.yml --ask-become-pass --tags "install_monitoring_tools"
```

Jeśli chcemy aby wykonały się wszystkie taski, które instalują aplikacje, to akurat tutaj mamy dwie opcje:

1. Podamy listę tagów: `--tags "install_monitoring_tools,install_text_editors"`
2. Podamy jeden wspólny tag: `--tags "packages"`

Usuń teraz aplikację `atop` oraz `htop` przy użyciu taga `remove_monitoring_tools`.

### Deployment kontenerów dockera z ansible

Przeanalizuj playbooka `run-containers.yml`, co się stanie kiedy puścimy go bez żadnych tagów?

Spróbuj wykonać poniższe zadania:

1. Postaw cały deployment wordpressa wykorzystując ten playbook - po prostu go uruchom. Ten playbook wykorzystuje `docker-compose.yml` ze `step-1`.
2. Zmień playbook tak aby wszystkie kontenery były w statusie `stopped`. (https://docs.ansible.com/projects/ansible/latest/collections/community/docker/docker_compose_v2_module.html)
3. Używając tagów usuń cały deployment bez usuwania wolumenów.
4. Używając tagów usuń nieużywane wolumeny.

### Inventory

Inventory w ansible to spis wszystkich serwerów wraz z ich ewentualnymi zmiennymi.

W folderze `inventory` znajdują się dwa pliki, oba zawierają dokładnie te same ustawienia i zmienne. W zależności od tego jaki format ci pasuje możesz używać plików w formacie **YAML** lub **INI**. Przy czym **INI** wcale nie jest kompatybilny z formatowanie **INI**.

Żeby to sprawdzić wykonaj playbooka `templates.yml` z argumentem `-i playbooks/inventory/hosts.ini` oraz `-i playbooks/inventory/hosts.yml`. Za każdym razem sprawdź zawartość pliku `index.html`.

Dlaczego w `index.html` pojawia się `Hello World! - YAML/INI Format`? A nie po prostu `YAML/INI Format`?

Spróbuj usunąć z pliku `hosts.yml` linijkę z `my_variable: "Hello World! - YAML format"` i puść playbooka z tym inventory jeszcze raz. Jaki jest Efekt?

Więcej o precedencji zmiennych: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable

Którego formatu lepiej użyć? Tego, który jest dla ciebie wygodniejszy. Ja proponuje nauczyć się formatu **YAML**, ponieważ wydaje mi się, że jest wygodniejszy w utrzymywaniu sporej ilości zmiennych per host.

#### Zmienne w plikach

Jest jeszcze opcja utrzymywania zmiennych w plikach (foldery `vars` oraz z sufiksem `_vars`): https://docs.ansible.com/projects/ansible/latest/tips_tricks/sample_setup.html#sample-directory-layout

### Struktura folderów

Ansible ma z góry ustaloną strukturę folderów, zresztą taką strukturę możecie zauważyć w naszym folderze `step-2/playbooks`.

Więcej o strukturze folderów w ansible: https://docs.ansible.com/projects/ansible/latest/tips_tricks/sample_setup.html#sample-directory-layout

### Role

> [!NOTE]
> Wykorzystamy tutaj taski z playbooka, który robił nam deployment kontenerów.
> Nie jest to zbyt poprawne wykorzystanie roli w tym celu, ale łatwiej będzie wam zrozumieć co się dzieje na taskach, które już znacie.

Role w ansible to zestaw tasków, które zapewniają nam działanie lub instalację jakiejś aplikacji na serwerze. Załóżmy, że chcemy na naszej grupie serwerów zainstalować dockera lub serwer WWW i skonfigurować go pod siebie, to możemy do tego użyć właśnie roli.

Albo mamy grupę serwerów WWW i drugą grupę serwerów bazodanowych, możemy stworzyć dwie osobne role i zdefiniować, która rola ma dotyczyć której grupy serwerów.

Wykonaj poniższe zadania:

1. Puść playbook `roles.yml` z inventory INI lub YAML.
2. Puść go z tagami `remove_deployment` oraz `remove_unused_volumes`.

Jak myślisz dlaczego przed nazwą tasków są prefixy:

- `deploy |`
- `remove |`
- `prune-volumes |`

i czy są wymagane?

> [!NOTE]
> Nie są wymagane, ale jest to dobra praktyka aby ten prefix był taki sam jak nazwa pliku w którym dany task się znajduje.
> To bardzo ułatwia debugowanie problemów.

#### Ansible galaxy - czyli kolekcje i role udostępnione przez społeczność

Czy trzeba samemu tworzyć role? Na szczęście nie, jest specjalna strona, która udostępnia nam role oraz kolekcje (moduły, np.: `community.docker.docker_prune`). Ta strona to ansible galaxy: https://galaxy.ansible.com/ui/

Instalacja roli jest banalnie prosta, na naszym kontrolerze musimy wykonać komendę `ansible-galaxy install <nazwa>`. Nie chodzi tu o zainstalowanie dockera u nas na kontrolerze, ale tak na prawdę o pobranie tasków z tej roli do nas lokalnie na kontroler.

W ostatniej części zajęć wykorzystamy rolę `geerlingguy.docker`, która zainstaluje nam dockera na naszym serwerze: https://galaxy.ansible.com/ui/standalone/roles/geerlingguy/docker/

Rolę tą wykorzystamy później wpisując:

```yaml
---
- name: Configure OS
  hosts:
    - all
  gather_facts: true
  become: true
  roles:
    - geerlingguy.docker
```
