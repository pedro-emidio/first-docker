# Docker

## Sobre o repositório

Este repositório tem o objetivo explicar brevemente o que foi feito neste projeto e demonstrar como executar a aplicação em contêiner. O projeto utiliza `Django` (Python) com `PostgreSQL`, `Docker` e `Nginx`. 

## Sobre o Docker

`Docker` é uma plataforma para desenvolvimento, envio e execução de aplicativos. O
`Docker` permite a separação dos aplicativos e infraestrutura, assim agilizando o ciclo
de vida do desenvolvimento de software. Tem como uma das principais características a implantação responsiva e escalonável.

## Ambiente virtual Python

Para criar e ativar o ambiente virtual (Ubuntu).

```bash
python3 -m venv venv				#cria
source venv/bin/activate			#ativa
```

## Django

Para instalar o `Django` e iniciar o projeto (nome: `testeDocker`)

```bash
pip install django				#instala o django
django-admin startproject testeDocker .	#starta o projeto
```

## Requirements do Python

1. Criar arquivo requirements.txt na raiz do projeto
2. Utilizar o comando:

```bash
pip freeze > requirements.txt
```

1. Adicionar a seguinte linha ao final do arquivo (adaptador de banco de dados PostgreSQL): `psycopg2-binary==2.8.6`

## Dockerfile

São como contêineres do aplicativo, ou como construir um novo contêiner a partir de uma imagem pré-construída e adicionamos à lógica personalizada para iniciação da aplicação. O `Dockerfile` é um documento de texto que contém todos os comandos que um usuário pode chamar na linha de comando para montar uma imagem. Com o uso de `docker build .` usuários podem criar um build automatizado que executa várias instruções de linha de comando em sucessão.

### Dockerfile Python

Criar arquivo chamado Dockerfile (sem extensão) na raiz do projeto com o seguinte conteúdo:

```docker
# Define a versão do Python que sera usada como base pra contruir a imagem
FROM python:3.8			

# Variavel de ambiente responsavel por não gerar arquivos .pyc
ENV PYTHONDONTWRITEBYTECODE 1		
# Variavel de ambiente responsavel por não guardar aquivos de log em buffer
ENV PYTHONUNBUFFERED 1	

# Define o diretório de trabalho		
WORKDIR /code

# Copia o arquivo para o diretório /code
COPY requirements.txt .
# "Roda" o comando responsavel por instalar as dependências do projeto
RUN pip install -r requirements.txt

# Todo o contúdo da pasta local (testeDocker2) será enviado para pasta code
COPY . .
```

### Dockerfile Nginx

O Nginx é um software de servidor web de código aberto.

Três arquivos são necessários para  configurar o Nginx corretamente, o primeiro é o `dockerfile`, na raiz do projeto crie um pasta chamada `nginx` e insira nela o arquivo `dockerfile` com o seguinte conteúdo:

```docker
# Define a versão do nginx que sera usada como base pra contruir a imagem
FROM nginx:1.19.0-alpine

# Roda o comando responsavel por removerr o arquivo de configuração padrão do Nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copia o aquivo citado para a pasta conf.d para subistituir o arquivo apagado anteriormente
COPY nginx.conf /etc/nginx/conf.d
```

Agora é necessário criar o arquivo `nginx.conf` (responsável por definir as configurações do Nginx), na mesma pasta (`nginx`).

Conteúdo:

```json
upstream testeDocker2 {
    server web:8000;
}

server {
    listen 80;

    location / {
        proxy_pass http://testeDocker2;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;
    }

}
```

Por fim, na raiz do projeto criar um arquivo chamado `startserver.sh` , que contem alguns comando necessários para iniciar o serviço quando usamos o `docker compose`. O conteúdo: 

```bash
fi
(cd testeDocker2; gunicorn testeDocker2.wsgi --user www-data --bind 0.0.0.0:8000 --workers 3 --timeout 180) &
nginx -g "daemon off;"
```

## Docker Compose

É um fluxo de trabalho automatizado de vários contêineres. Com o `Compose`, você usa um arquivo `.YAML` para configurar os serviços do seu aplicativo. O `docker compose` pode gerar uma imagem definida pelo `Dockerfile`, sendo assim, não é possível criar uma imagem pelo `docker compose`, somente utilizar uma já existente.

Criar arquivo chamado `docker-compose.yml` na raiz do projeto com o seguinte conteúdo:

```yaml
# Versão do docker compose file format (sintaxe)
version: "3.8"
  # Serviço web
	services:
	  web:                                                   
	    build: .                                            # Caminho para o construir a aplicação 
	    command: python manage.py runserver 0.0.0.0:8000    # Executa o comando de inicialização do django
	    volumes:                                                # Sincroniza os arquivos da aplicação com os do Docker 
	      - .:/code
	    ports:
	      - 8000:8000                                       # expoem a porta 8000 (padão django)        
	    depends_on:                                             # Define que o seriço web depende do serviço DB, logo o serviço DB sera inicializado antes do web
	      - db

	# Serviço Nginx
  nginx:
    build:                                             # Informações referentes ao build do ngnx 
      context: ./nginx/                                 
      dockerfile: dockerfile
    ports:                                             # Expoem a porta 80 (padrão Nginx)
      - 80:80
    depends_on:                                        # Define que o serviço nginx depende o web, logo sera executado após o serviço web
      - web

	#serviço do Banco de dados 
  db:
	  image: postgres:13                                  # Define a imagem base do baco de dados 
	  environment:
		  - POSTGRES_USER=postgres                          # Variavel de ambiente que define o usuário do banco
		  - POSTGRES_PASSWORD=postgres                      # Variavel de ambiente que define a senha do banco
    volumes:
	    - postgres_data:/var/lib/postgresql/data/         # Responsavel por fazer com que os dados do banco persistam 
volumes:
    postgres_data:--
```

## Comandos Necessários

Neste ponto, ao rodar o comando abaixo a aplicação do contêiner já deve estar funcionado em `localhost:80`.

```bash
docker-compose up -d
```

Para derrubar o serviço: 

```bash
docker-compose down
```

### Alterações no projeto

Em caso de alterações no projeto é necessário forçar que o contêiner seja construído novamente, isso pode ser feito com o comando:

```bash
docker-compose up --build
```

### Migrações

No `Django`, em caso de alterações do banco de dados é necessário executar alguns comandos para efetivamente implantar essas alterações (`python manage.py makemigrations`& `python manage.py migrate`), porém, para que essas alterações sejam sincronizadas entre o ambiente de desenvolvimento e o contêiner é necessário executa-los da seguinte maneira:

```bash
docker-compose exec web python manage.py makemigrations
docker-compose exec web python manage.py migrate
```
