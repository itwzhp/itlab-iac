# Instrukcje

- [Instrukcje](#instrukcje)
  - [1. Przygotuj środowisko](#1-przygotuj-środowisko)
    - [Azure](#azure)
  - [2. Step 0 - Azure Service Principal](#2-step-0---azure-service-principal)
    - [Azure Service Principal](#azure-service-principal)
  - [3. Sklonuj repo](#3-sklonuj-repo)
  - [4. Utwórz repozytorium na twoim koncie GitHub](#4-utwórz-repozytorium-na-twoim-koncie-github)
    - [Przygotowanie repozytorium](#przygotowanie-repozytorium)

## 1. Przygotuj środowisko

Żeby nie tracić czasu podczas naszych krótkich zajęć wykonajcie poniższe kroki na laptopie, którego będziecie używać podczas zajęć z **Infrastruktury jako kod (IaC)**.

1. Załóż darmowe konto **(INNE NIŻ ZHP)** na Azure (https://portal.azure) - jeśli zakładasz je pierwszy raz to dostaniesz 200$ do wykorzystania na 30 dni + pełno serwisów jest za darmo przez pierwszych 12 miesięcy.
   Jeśli już masz konto, to nie przejmuj się, wykorzystamy maksymalnie złotówkę.
  
2. Zainstaluj WSL2 (tylko dla użytkowników Windows). Uwaga musisz w BIOS/UEFI załączyć wirtualizację ([Enable Virtualization on Windows](https://support.microsoft.com/en-us/windows/enable-virtualization-on-windows-c5578302-6e43-4b4b-a449-8ced115f58e1)) - https://learn.microsoft.com/en-us/windows/wsl/install:
   1. Na WSL2 zainstaluj **ansible** komendą `sudo apt update && sudo apt install pipx -y && pipx install --include-deps ansible && pipx runpip ansible install docker && pipx ensurepath && . .bashrc`. Sprawdź działanie wpisując `ansible --version`.
  
   2. Zainstaluj **git** komendą `sudo apt update && sudo apt install git -y`.
     Sprawdź działanie wpisując `git --version`.
  
   3. Zainstaluj **terraform** zgodnie z instrukcjami dla Linux Ubuntu/Debian - https://developer.hashicorp.com/terraform/install.
     Sprawdź działanie wpisując `terraform --version`.

   4. Zainstaluj **Azure CLI** - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt (Przejdź do Option 1).
     Sprawdź działanie komendą `az login`, powinno wyskoczyć okienko w twojej przeglądarce do zalogowania się do platformy Azure, spróbuj się zalogować. Jeśli przeglądarka się nie odpali to powinien pokazać się w konsoli URL do zalogowania.
     A jeśli nawet ta metoda zawiedzie, to można wywołać logowanie kodem urządzenia: `az login --use-device-code`.
     Po zalogowaniu sprawdź jako kto jesteś zalogowany komendą `az account show`.
  
   5. Utwórz nowy klucz SSH komendą `ssh-keygen -t ed25519 -f ~/.ssh/id_itlab -N ""`. Dwa klucze powinny być widoczne po wpisaniu komendy `ls -la ~/.ssh/id_itlab*`
  
   6. Dodajmy też sobie bardzo przydatny alias do komendy dockera, tak żebyśmy nie musieli za każdym razem wpisywać `sudo docker` tylko samo `docker`. Wpisz w konsoli: `echo "alias docker='sudo docker'" >> ~/.bashrc`
  
3. Zainstaluj docker desktop - https://docs.docker.com/desktop/setup/install/windows-install/
  
4. Jeśli nigdy nie korzystałeś i nie masz swojego ulubionego IDE to zainstaluj vscode. Będzie nam potrzebne do pisania kodu bezpośrednio na WSL2 (nie wiem czy inne IDE mają coś takiego dostępne) - https://code.visualstudio.com/
   1. Wtyczki są opcjonalne, ale pomogą nam w pisaniu i formatowaniu kodu (zwłaszcza jeśli nigdy tego nie robiłeś :) ):
      1. Docker
      2. HashiCorp Terraform
      3. indent-rainbow
      4. Python
      5. WSL

### Azure

Musimy także przygotować nasze środowisko w Azure.

1. W szukajce u góry wyszukaj **Storage Accounts**
2. Kliknij **Create** i wypełnij formularz:
   1. **Basics:**
      1. Pod **Resource group** wybierz **Create new** i wpisz nazwę **tfstate-rg**
      2. **Storage account name**: tfstate+6 losowych znaków (nazwa musi być unikalna w całym Azure) np.: **tfstate1j3k4l**
      3. **Region**: North Europe
      4. **Performance**: Standard
      5. **Redundancy**: LRS
   2. Kliknij **Review + Create** i zaakceptuj zmiany
3. Po wykreowaniu (proces możesz podejrzeć klikając dzwoneczek w prawym górnym rogu), przejdź do nowo stworzonego zasobu klikając w **Go to resource**
4. Przejdź do **Data storage > Containers > Add container** i nazwij go **tfstate** i kliknij **Create**

## 2. Step 0 - Azure Service Principal

### Azure Service Principal

Musimy utworzyć konto, którym będziemy zdalnie zarządzać naszymi zasobami w Azure.

1. W szukajce wpisz **Subscriptions** i pobierz **Subscription ID**, zapisz numer gdzieś z boku w pliku, będzie nam potrzebny później.
  
2. Zaloguj się używając `az login` i wpisz komendę `az ad sp create-for-rbac --name "terraform-sp" --role Contributor --scopes /subscriptions/<SUBSCRIPTION_ID>` podmieniając `<SUBSCRIPTION_ID>` na twój numer.
  
3. W informacji zwrotnej dostaniesz dane w formacie JSON. **NIKOMU NIE PODAWAJ TYCH DANYCH**, dzięki nim można utworzyć dowolny zasób na Azure. Zapisz je w tym samym miejscu co **Subscription ID**.
  
4. Nasze konto musi mieć także jeszcze rolę **Storage Blob Data Contributor** przypisaną do stworzonego **Storage Account**:
  
   1. Znajdźmy najpierw ID komendą:
     `az ad sp list --display-name terraform-sp --query "[].{Name:displayName, AppId:appId}" -o table`
  
   2. A następnie przypiszmy ją komendą:
     `az role assignment create --assignee <APP_ID> --scope /subscriptions/<SUBSCRIPTION_ID>/ResourceGroups/tfstate-rg/providers/Microsoft.Storage/storageAccounts/<STORAGE_ACCOUNT_NAME> --role "Storage Blob Data Contributor"`, gdzie:
      1. **APP_ID** - to ID konta, które pobraliśmy we wcześniejszej komendzie
      2. **SUBSCRIPTION_ID** - to ID subskrypcji
      3. **STORAGE_ACCOUNT_NAME** - to nazwa waszego konta storage

## 3. Sklonuj repo

Sklonuj to repozytorium lokalnie przy użyciu VSCode.

Po otwarciu nowego okna VSCode kliknij w lewym dolnym rogu **><** i z listy, która się pojawi wybierz **Connect to WSL**.

Nastepnie wybierz **Clone Git Repository** i wklej `https://github.com/itwzhp/itlab-iac.git`.

## 4. Utwórz repozytorium na twoim koncie GitHub

Utwórz nowe **prywatne** repozytorium na twoim koncie GitHub: https://github.com/new o nazwie `my-itlab-iac`.

Otwórz nowe okno VSCode kliknij w lewym dolnym rogu **><** i z listy, która się pojawi wybierz **Connect to WSL**.

Następnie wybierz **Clone Git Repository** i wklej adres WWW, który widzisz pod **Quick setup — if you’ve done this kind of thing before**.

### Przygotowanie repozytorium

Przejdź do **Settings > Secrets and variables > Actions** i dodaj:

Repository secrets:

1. `ANSIBLE_VAULT_PASSWORD` - itlab
2. `AZURE_CREDENTIALS` - JSON w formacie:
   ```json
     {
       "clientSecret":  "******",
       "subscriptionId":  "******",
       "tenantId":  "******",
       "clientId":  "******"
     }
   ```
   Gdzie:
   
   `clientSecret` = `password` z naszego pliku JSON

   `subscriptionId` = subscription ID

   `tenantId` = `tenant` z naszego pliku JSON

   `clientId` = `appId` z naszego pliku JSON

3. `AZURE_SUBSCRIPTION_ID` - twoje Subscription ID
4. `SSH_KEY` - wynik komendy `cat ~/.ssh/id_itlab`. **NIKOMU NIE PODAWAJ TEGO KLUCZA!**
