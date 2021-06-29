# Define a imagem base que será usada usada para a construção da imagem
FROM python:3.8			

# Variavel de ambiente responsavel por não gerar arquivos .pyc
ENV PYTHONDONTWRITEBYTECODE 1		
# Variavel de ambiente responsavel por não guardar aquivos de log em buffer
ENV PYTHONUNBUFFERED 1	

# Define o diretório de trabalho		
WORKDIR /home/pedro/dev/testeDocker2

# Copia o arquivo para o diretório /code
COPY requirements.txt .
# "Roda" o comando responsavel por instalar as dependências do projeto
RUN pip install -r requirements.txt

# Todo o contúdo da pasta local (testeDocker2) será enviado para pasta code
COPY . /home/pedro/dev/testeDocker2/

EXPOSE 8000