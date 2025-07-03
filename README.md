# RgPet App

Um aplicativo móvel de gestão veterinária desenvolvido com Flutter e Firebase, projetado para atender às necessidades tanto de donos de pets quanto de veterinários, oferecendo funcionalidades personalizadas para cada tipo de usuário.

## 🌟 Funcionalidades

### Autenticação e Perfis
* **Login de Usuário:** Autenticação por e-mail e senha.
* **Cadastro de Dono:** Registro de novos donos de pet com informações como nome completo, CPF, endereço, telefone e e-mail.
* **Cadastro de Veterinário:** Registro de novos veterinários com nome completo, CRMV, especialização, telefone e e-mail.
* **Redefinição de Senha:** Funcionalidade "Esqueci minha senha" para recuperação de acesso via e-mail.
* **Redirecionamento por Tipo de Usuário:** Após o login, o usuário é automaticamente direcionado para a dashboard de Dono ou Veterinário, com base em seu perfil no Firestore.
* **Visualização de Perfil:** Telas dedicadas para exibir os dados completos do perfil de Dono e Veterinário, carregados do Firestore.
* **Sair da Conta:** Botões de logout disponíveis nas dashboards e nas telas de perfil.

### Para Donos de Pets
* **Saudação Personalizada:** "Olá, [Nome do Dono]!" na tela inicial do dono, buscando o nome completo do Firestore.
* **Gestão de Pets:**
    * **Cadastro de Pet:** Formulário para registrar novos pets, incluindo nome, tipo de animal, raça, idade e peso.
    * **Listagem de Pets:** Exibe uma lista simplificada dos pets cadastrados pelo dono.
    * **Mensagem de "Sem Pets":** Caso o dono não tenha pets cadastrados, uma mensagem informativa e um botão para iniciar o cadastro são exibidos.
    * **Detalhes do Pet:** Tela dedicada para visualizar todas as características de um pet específico.
* **Agendamento de Consulta:** Tela para agendar consultas, permitindo selecionar o pet, o veterinário, a data, a hora e o motivo da consulta, com dados carregados do Firebase.

### Para Veterinários
* **Saudação Personalizada:** "Olá, [Nome do Veterinário]!" na tela inicial do veterinário, buscando o nome completo do Firestore.
* **Gestão de Horários:** Tela para o veterinário gerenciar seus horários disponíveis, adicionando ou removendo slots de tempo.
* **Sistema de Notificação:** Veterinários recebem notificações sobre novas solicitações de consulta, exibidas com um contador de mensagens não lidas.
* **Gerenciamento de Solicitações:** Tela para o veterinário visualizar consultas com status "pendente" e optar por confirmá-las (mudando o status para 'confirmado') ou rejeitá-las (liberando o horário na agenda).

### Interface do Usuário (UI)
* Tema escuro com cores personalizadas (vermelho, amarelo/laranja, tons de cinza).
* Componentes reutilizáveis como `CustomTextField` e `CustomButton`.
* Bottom Navigation Bar para fácil acesso às seções principais (Home, Agenda/Consultas, Pets/Pacientes, Perfil).
* Ícones centralizados nos botões de ação na dashboard.

## 🛠️ Tecnologias Utilizadas

* **Flutter:** Framework para desenvolvimento de aplicativos móveis multiplataforma.
* **Dart:** Linguagem de programação.
* **Firebase Authentication:** Para gerenciamento de usuários (cadastro, login, redefinição de senha).
* **Cloud Firestore:** Banco de dados NoSQL para armazenar dados dos usuários (perfis, pets, consultas).

## 🚀 Como Começar

### Pré-requisitos

* [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado e configurado.
* Um editor de código (VS Code com a extensão Flutter, ou Android Studio).
* Um emulador Android/iOS ou um dispositivo físico.
* Uma conta Google para configurar o projeto Firebase.

### Configuração do Projeto Firebase

1.  **Crie um Projeto Firebase:**
    * Acesse o [Console do Firebase](https://console.firebase.google.com/).
    * Crie um novo projeto (ex: `rgpet-961cd`).
2.  **Configure a Autenticação:**
    * No painel esquerdo do Firebase Console, vá em `Build > Authentication`.
    * Clique em "Primeiros passos" e ative o método de login por "E-mail/Senha".
3.  **Configure o Cloud Firestore:**
    * No painel esquerdo, vá em `Build > Firestore Database`.
    * Clique em "Criar banco de dados" e selecione "Iniciar em modo de teste" para facilitar o desenvolvimento (você pode ajustar as regras de segurança depois).
    * Selecione uma localização para o seu banco de dados.
    * **Regras de Segurança:** Para depuração, você pode usar temporariamente a regra `allow read, write: true;` ou `allow read, write: if request.auth != null;` para permitir a escrita.
    * **Criação de Índices:** O Cloud Firestore exige índices compostos para consultas com múltiplas condições `where()` e/ou `orderBy()`. O console do Firebase fornecerá links diretos para criar os índices necessários caso sua aplicação os solicite durante a execução.
4.  **Adicione os Aplicativos ao Projeto Firebase:**
    * No Firebase Console, na visão geral do projeto, adicione um aplicativo Android e um aplicativo iOS ao seu projeto.
    * Siga as instruções para baixar os arquivos de configuração (`google-services.json` para Android e `GoogleService-Info.plist` para iOS) e coloque-os nas pastas corretas do seu projeto Flutter (`android/app/` e `ios/Runner/`).
5.  **Instale e Configure o FlutterFire CLI:**
    * Instale o FlutterFire CLI: `dart pub global activate flutterfire_cli`
    * No diretório raiz do seu projeto Flutter, configure o Firebase para o Flutter: `flutterfire configure`
    * Isso irá gerar o arquivo `lib/firebase_options.dart` com as configurações do seu projeto.

### Execução do Aplicativo

1.  **Clone o Repositório:**
    ```bash
    git clone [URL_DO_SEU_REPOSITORIO]
    cd rgpet
    ```
2.  **Instale as Dependências:**
    ```bash
    flutter pub get
    ```
3.  **Limpe o Projeto (Recomendado após setup inicial ou problemas de build):**
    ```bash
    flutter clean
    ```
4.  **Execute o Aplicativo:**
    ```bash
    flutter run
    ```
    O aplicativo será iniciado em seu emulador ou dispositivo conectado.

## 🚀 Próximos Passos e Melhorias Futuras

* Implementar a exibição de consultas agendadas e histórico de consultas para donos e veterinários.
* Desenvolver a funcionalidade de "Meus Pets" na `TelaDono` para listar e gerenciar pets cadastrados.
* Funcionalidade de edição de perfil para donos e veterinários.
* Implementar busca de pacientes/pets para veterinários.
* Notificações em tempo real para consultas e eventos importantes.
* Funcionalidade de chat entre donos e veterinários.
* Testes unitários e de integração.
* Otimização de UI/UX e melhorias de design.

## 🤝 Contribuição

Contribuições são bem-vindas! Se você tiver sugestões, relatar bugs ou quiser adicionar recursos, por favor, sinta-se à vontade para abrir uma issue ou enviar um pull request.