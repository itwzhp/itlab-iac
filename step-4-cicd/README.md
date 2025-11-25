# Step 4 - CI/CD

- [Step 4 - CI/CD](#step-4---cicd)
  - [Struktura projektu](#struktura-projektu)
  - [GitHub Actions](#github-actions)
    - [Docker compose i ansible vault](#docker-compose-i-ansible-vault)
    - [Playbooki](#playbooki)
    - [Pipeline uruchomienie](#pipeline-uruchomienie)
    - [Pipeline - jak to działa](#pipeline---jak-to-działa)
      - [Sposoby uruchamiania](#sposoby-uruchamiania)
      - [Joby i stepy](#joby-i-stepy)
      - [Zmienne środowiskowe](#zmienne-środowiskowe)
      - [Secrety i zmienne w pipeline'ach](#secrety-i-zmienne-w-pipelineach)
  - [Sprzątanie](#sprzątanie)

Skopiuj wszystkie pliki z tego folderu do swojego wcześniej przygotowanego repozytorium `itlab-iac`.

Skopiuj folder `terraform` z folderu `step-3-terraform` do swojego repozytorium.

W pliku `providers.tf` usuń linijkę z `subscription_id`. Wykorzystamy zmienną środowiskową `ARM_SUBSCRIPTION_ID`, zamiast bezpośrednio ją wpisywać do pliku `providers.tf`, co nie jest zalecane.

W pliku `vm.tf` musimy zmienić lokalizację w której ma się pojawić plik hosts.ini.
Zmień:

```tf
resource "local_file" "ansible_inventory" {
  content = templatefile("templates/inventory.tpl", 
    {
      vm_public_ip = azurerm_public_ip.pip.ip_address
      ansible_user = var.vm_user_name
    }
  )
  filename = "${path.module}/hosts.ini"
}
```

Na:

```tf
resource "local_file" "ansible_inventory" {
  content = templatefile("templates/inventory.tpl", 
    {
      vm_public_ip = azurerm_public_ip.pip.ip_address
      ansible_user = var.vm_user_name
    }
  )
  filename = "${path.module}/../ansible/playbook/inventory/hosts.ini"
}
```

## Struktura projektu

1. `.github/workflows/` - folder zawierający pipeline'y (rurociągi, dla purystów językowych), czyli taski które mają zostać wykonane na runnerze. Runner to serwer, który przekłada taski na konkretne operacje i komendy.
2. `ansible/playbook/` - playbooki i role ansible.
3. `collections/requirements.yml` - plik z wymaganymi kolekcjami i rolami pobieranymi z ansible galaxy.
4. `terraform` - akcje wykonywane przez terraform.

## GitHub Actions

GitHub Actions to jedna z wielu platform/aplikacji do CI/CD (Continous Integration and Continous Delivery), czyli do automatyzacji wdrożeń aplikacji, konfiguracji serwerów itd..

### Docker compose i ansible vault

Jeśli przeanalizujesz plik `ansible/playbook/roles/wordpress/templates/docker-compose.yml` to zauważysz, że zamiast haseł są tam zmienne. Te zmienne znajdują się w pliku stworzonym przy użyciu ansible vault:

```bash
ansible-vault edit ansible/playbook/roles/wordpress/vars/credentials.yml
```

Podaj hasło `itlab` i zauważysz, że wszystkie zmienne zostały tam schowane. Automatycznie otwiera się edytor `vim`, który nie jest najbardziej przyjaznym edytorem dla początkujących. Żeby z niego wyjść kliknij po kolei: `Esc`, `:`, `q`, `Enter`.

> [!NOTE]
> Jeśli chcesz zapoznać się z edytorem `vim` to polecam **VIM Adventures**: https://vim-adventures.com/

Ansible vault jest świetnym wyborem jeśli będziesz miał dużo haseł i zmiennych, które muszą być ukryte, w swoich playbookach i templatkach. Inaczej musiałbyś je wszystkie dopisywać do secretów w GitHub Actions.

Kiedy ten vault jest otwierany podczas naszych playbooków?

### Playbooki

Mamy 2 playbooki:

1. `configure-os.yml` - zainstaluje nam tylko jedną rolę, `geerlingguy.docker` który postawi nam na serwerze dockera.
2. `deploy-wordpress.yml` - uruchomi rolę `wordpress`, która uruchomi nam deployment wordpressa na serwerze. Pierwszym taskiem jest załadowanie vaulta `credentials.yml`.
   1. Taski w `copy-docker-config.yml` utworzą nam folder na podstawie zmiennej `docker_containers_dir` i skopiują tam templatkę `docker-compose.yml`.
   2. Taski w `start-containers.yml`, podniosą nam kontenery i wykonają pruning.

### Pipeline uruchomienie

Po skopiowaniu i modyfikacji plików, wykonaj w konsoli:

```bash
git add .
git commit -m "Initial commit"
git push
```

Przejdź do swojego repozytorium na github z górnego menu wybierz **Actions > Deploy itlab-app**, a następnie **Run workflow**.

Całe środowisko powinno się automatycznie uruchomić po kilku minutach. Jak przjdziemy do naszego pipeline'a i znajdziemy task o nazwie **Terraform Apply**, to znajdziemy tam adres IP naszej VMki:

```bash
Run terraform -chdir=terraform apply -auto-approve tf-plan
Acquiring state lock. This may take a few moments...
local_file.ansible_inventory: Creating...
local_file.ansible_inventory: Creation complete after 0s [id=1c0368e740c5d7d391ef7bc842b4c3af298d6548]
Releasing state lock. This may take a few moments...

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

vm_public_ip = "134.149.27.38"
```

Przejdźmy pod niego i zobaczmy czy Wordpress działa.

No nie działa, ponieważ został użyty obraz wordpressa bez serwera WWW. W pliku `ansible/playbook/roles/wordpress/templates/docker-compose.yml` zmieńmy linijkę `image: wordpress:6-fpm-alpine`, na `image: wordpress:6`, wypchinjmy zmiany i ponownie uruchommy pipeline.

Teraz powinno być wszystko ok.

### Pipeline - jak to działa

Każda platforma do CI/CD posiada swój język, którym deklarujemy jakie akcje mają zostać wykonane. W GitHub Actions jest to **YAML**, który ma określoną strukturę.

#### Sposoby uruchamiania

Pipeline może uruchamiać się:

1. Automatycznie, za każdym razem jak zrobicie na przykład push commita do repozytorium, albo gdy stworzycie pull request (PR)
2. Automatycznie o określonym czasie.
3. Manualnie

Ta deklaracja zaczyna się od słowa `on`:

```yaml
on:
  push:
    branches: ['main']
    # don't rebuild image if someone only edited unrelated files
    paths-ignore:
      - 'README.md'
      - '.gitignore'
  # You can run this action manually
  workflow_dispatch:
```

Powyższy pipeline uruchomi się automatycznie po każdym pushu do brancha `main`, oprócz momentów kiedy powstaną lub zostaną zmodyfikowane pewne pliki. Ale też dzięki zadeklarowaniu `workflow_dispatch` mozna go uruchomić manualnie.

#### Joby i stepy

Mamy tutaj strukturę hierarchiczną:

1. Job 1
   1. Step 1
   2. Step 2
2. Job 2
   1. Step 1
   2. Step 2
   3. Step 3
3. itd..

Wszystkie joby są uruchamiane w tym samym czasie, chyba że mają zadeklarowaną zależność od innego joba. Wtedy będą czekały na jego zakończenie.

Stepy w jobie są uruchamiane jeden po drugim.

https://docs.github.com/en/actions/get-started/understand-github-actions#the-components-of-github-actions

W naszych pipeline używamy stepów, które są po prostu komendami w linuxie:

```yaml
      - name: Terraform Plan
        run: terraform -chdir=terraform plan -out tf-plan 
```

Ale mamy także stepy, które składają się z większej ilości stepów. Weźmy na przykład `hashicorp/setup-terraform@v3`. Skąd mamy nazwę i co robi to `v3` na końcu. Kolejne pytanie brzmi czym jest słowo `with:` i co robi po nim jakiś parametr `terraform_version: "1.13.5"`.

Github posiada coś takiego jak marketplace: https://github.com/marketplace

Możemy wpisać w szukajkę `hashicorp/setup-terraform` lub kliknąć tutaj: https://github.com/marketplace/actions/hashicorp-setup-terraform

Rozbijmy teraz poniższy step na części:

```yaml
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.13.5"
```

1. `name` - to nic innego jak wyświetlana nazwa
2. `uses: hashicorp/setup-terraform@v3`:
   1. `hashicorp/setup-terraform` - to tak na prawdę repozytorium: https://github.com/hashicorp/setup-terraform
   2. `v3` - to może być nazwa brancha lub taga (tak jest akurat tutaj): https://github.com/hashicorp/setup-terraform/tags
3. `with:` - to deklaracja parametrów, te znajdziemy na wcześniej wspomnianmym marketplace.

I właśnie z takich klocków składamy cały nasz pipeline. Moglibyście po prostu napisać komendy tak jak to robiliśmy do tej pory, ale jest to mało powtarzalne i ciężko się takie coś utrzymuje. Polecam jednak trzymać się stepów, które posiadają jakąś renomę.

#### Zmienne środowiskowe

Zmienna środowiskowa to prosta wartość (np. tekst lub liczba), którą system operacyjny lub program przechowuje „w tle”, żeby inne programy mogły jej używać.

Możesz myśleć o niej jak o etykiecie z informacją, którą komputer „przekazuje” różnym programom.

W naszym pipeline mamy 1 zmienną środowiskową:

1. `ARM_SUBSCRIPTION_ID` - z tej zmienne korzysta terraform, usuwaliśmy na początku `subscription_id` z pliku `providers.tf` właśnie z tego powodu.

#### Secrety i zmienne w pipeline'ach

Na początku wpisywaliśmy secrety dla pipeline'ów. Jak spojrzysz na pliki w `.github/workflow` to znajdziesz tam wpisy takie jak na przykład: `${{ secrets.AZURE_CREDENTIALS }}`. Zmienna secrets jest tak na prawdę słownikiem i tutaj prosimy ją o zwrócenie wartości dla klucza `AZURE_CREDENTIALS`.

Po co używać secrets? Ponieważ w logach pipeline'a te zmienne są zamaskowane gwiazdkami.

```bash
id=/subscriptions/***/resourceGroups/itlab
```

Dokładnie tak samo byłoby gdybyśmy chcieli zadeklarować zmienne dla pipeline'ów, tylko wtedy słownik nazywa się `vars`, czyli na przykład: `${{ vars.MOJA_ZMIENNA }}`. Zmienne w przeciwieństwie do secretów nie są ukrywane.

Mamy też w pipeline deklarację zmiennych środowiskowych:

```yaml
env:
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

Do nich odwołujemy się używają słownika `env`, czyli na przykład: `${{ env.ARM_SUBSCRIPTION_ID }}`.

## Sprzątanie

Przejdź do swojego repozytorium na github z górnego menu wybierz **Actions > Destroy itlab environment**, a następnie **Run workflow**.

### Azure

Usuń konto Service Principal z **Azure**:

1. Przejdź na https://portal.azure i w szukajce znajdź **Subscriptions**
2. Wybierz swoją subskrypcję
3. Wybierz **Access control (IAM)**
4. Wybierz **Role Assignments**
5. Zaznacz obie role `terraform-sp` i u góry wybierz **Delete**

Usuń Resource Groups:

1. Przejdź na https://portal.azure i w szukajce znajdź **Resource Groups**
2. Kliknij w **itlab** na liście i wybierz u góry **Delete resource group**. Jeśli nie masz takiej grupy, to przejdź do następnego kroku.
3. Kliknij w **itlab-rg** na liście i wybierz u góry **Delete resource group**.
