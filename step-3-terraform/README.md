# Step 3 - Terraform

- [Step 3 - Terraform](#step-3---terraform)
  - [Terraform](#terraform)
  - [Inicjalizacja](#inicjalizacja)
  - [Plan](#plan)
  - [Apply](#apply)
  - [Plik tfstate](#plik-tfstate)
  - [Destroy](#destroy)

Będąc w głownym folderze repozytorium przejdź do folderu: `cd step-3-terraform/terraform`.

Przygotuj:

1. Subscription ID z Azure
2. JSONa, którego dostałeś kiedy tworzyłeś konto Service Principal

## Terraform

Terraform to narzędzie, które pozwala nam w łatwy sposób zdefiniować całą naszą infrastrukturę. Najczęściej wykorzystujemy go do uruchamiania środowiska w chmurze typu AWS, Azure, GCP itp.. Lista jest ogromna: https://registry.terraform.io/browse/providers

Jako, że to narzędzie jest mocno rozbudowane to ze względu na czas nie będziemy się nim za bardzo zajmować. Użyjemy go tylko i wyłącznie do ręcznego utworzenia środowiska w Azure, a później zobaczymy jak zautomatyzować jego działanie.

## Inicjalizacja

Przed użyciem terraform musimy go zainicjalizować komendą

```bash
terraform init
```

To zainstaluje nam potrzebne wtyczki w folderze `.terraform` i stworzy plik `.terraform.lock.hcl`, dzięki któremu przez przypadek nie zostaną pobrane nowsze wersje paczek i będziemy mieli pewność, że wszystko działa tak jak powinno podczas wdrażania automatyzacji.

## Plan

Przed zaaplikowaniem zmian przy użyciu terraform, najczęściej tworzy się plan.

Zanim to zrobimy zalogujmy się do azure przy użyciu:

```bash
az login
```

Następnie w pliku `providers.tf` podmień `subscription_id` na swoje, a w pliku `variables.tf` podmień:

1. `ssh_pub_key` na wynik komendy `cat ~/.ssh/id_itlab.pub`.

```bash
terraform plan -out tf-plan
```

W outpucie dostaniesz informację co zostanie zmienione w twoim środowisku i jakie zasoby zostaną utworzone. Powstanie także specjalny plik, którego użyjemy przy aplikowaniu zmian.

> [!WARNING]
> **NIGDY nie commituj do repozytorium Git żadnych informacji, które są wrażliwe!**
> Głównie chodzi o:
>
> 1. Hasła
> 2. Tokeny
> 3. Prywatne klucze SSH (te bez końcówki `.pub`)
> 4. Różne ID ze środowiska chmurowego typu: application id, tenant id, subscription id itd.. Są one unikalne i wskazują bezpośrednio na twoje zasoby.
>
> Takie rzeczy przetrzymuje się w specjalnych vaultach takich jak Azure Vault, Hashicorp Vault, Ansible Vault lub Action Secrets w GitHub.

## Apply

Teraz przyszedł moment aby utworzyć nasze zasoby komendą:

```bash
terraform apply tf-plan
```

Po kilku minutach dostaniecie jako wynik tej komendy 2 rzeczy:

1. Plik `hosts.ini`, który jest inventory dla ansible
2. adres IP waszej wirtualnej maszyny (VMki).

Zalogujcie się na waszą maszynę wpisując: `ssh itlabadmin@<ADRES_IP> -i ~/.ssh/id_itlab`.

Spróbujcie też zobaczyć, czy jest już tam `docker`:

```bash
$ sudo docker ps -a
sudo: docker: command not found
```

Jeśli go nie ma, to wszystko jest w porządku.

## Plik tfstate

Plik `terraform.tfstate`, zawiera aktualny stan waszego środowiska, jeśli wykonamy znowu `terraform plan` to zobaczycie, że nic nie będzie do zmiany.

Zmieńcie teraz nazwę plików `terraform.tfstate` oraz `terraform.tfstate.backup` i dodajcie im na początku prefix `bak.`. Wykonajcie ponownie komendę `terraform plan`, co się stało?

Jakimś cudem terraform ponownie chce wszystko utworzyć. Jeśli kiedykolwiek stracicie plik `terraform.state`, to jego odzyskanie przy dużych środowiskach może być karkołomne: https://www.sharepointeurope.com/recovering-from-a-deleted-terraform-state-file/

> [!WARNING]
> **NIGDY nie commituj pliku `terraform.tfstate` do repozytorium Git!**
> Plik `terraform.tfstate` zawiera wrażliwe dane o całym twoim środowisku.
>
> Przechowuj go na zdalnym backendzie, najlepiej na storage'u obiektowym takim jak AWS S3, Azure Blob Storage, Terraform Cloud z włączonym szyfrowaniem i wersjonowaniem.
> Czym jest storage obiektowy i jak różni się od zwykłych dysków w waszych laptopach: https://www.youtube.com/watch?v=dEcQK4-pqiw

My użyjemy Azure Blob Storage jako backendu dla terraform. W folderze `step-3-terraform` znajduje się plik `backend.tf`, skopiuj go do folderu `terraform`.

Zmień `storage_account_name` na swój, który utworzyłeś i spróbuj teraz wykonać `terraform plan`. Terraform poinformuje nas, że zmieniliśmy backend i albo zrobimy reinicjalizację, albo zmigrujemy tfstate na nowy backend.

Wykonaj migrację:

```bash
terraform init -migrate-state
```

Mamy problem, nasze konto azure nie ma autoryzacji do zapisywania danych na naszym Blobie. Musimy znaleźć plik z danymi konta Service Principal lub przypisać sobie autoryzację.

Przelogujmy się na nasze konto SP poniższą komendą i wykonajmy jeszcze raz migrację oraz planning:

```bash
az login --service-principal --username APP_ID --password CLIENT_SECRET --tenant TENANT_ID
# APP_ID = appId
# CLIENT_SECRET = password
# TENANT_ID = tenant

terraform init -migrate-state

terraform plan
```

Efektem powinno być: `No changes. Your infrastructure matches the configuration.` po wykonaniu planowania.

## Destroy

Ostatnią komendą jest "zniszczenie" środowiska:

```bash
terraform destroy
```

To usunie wszystko co zostało stworzone przez terraform.
