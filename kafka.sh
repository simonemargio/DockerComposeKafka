#!/bin/bash

# ***************************************************************
# Author: Simone Margio
#
# All rights reserved. This code is released under the MIT License.
#
# Last release date: 09/02/2025
# ***************************************************************

# MIT License
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# provided to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Funzione che avvia il container Kafka in background
# Avvia Docker Compose in modalità detached
avvia_container_kafka() {
    docker-compose up -d
    echo "Container Kafka avviato in background."
}

# Arresta i container definiti nel file docker-compose.yml
ferma_container_kafka() {
    docker-compose down
    echo "Container Kafka fermato."
}

# Esegui il comando 'bash' nel container con nome 'smkafka' (si entra nella shell del container)
entra_nel_container() {
    echo "Per ritornare al menu principale scrivere 'exit' e dare INVIO."
    docker exec -it smkafka bash
}

# Funzione che esegue un comando all'interno del container Kafka
# Il comando passato come argomento viene assegnato alla variabile 'comando'
esegui_comando_kafka() {
    comando=$1
    docker exec -it smkafka bash -c "$comando"
}

# Funzione che crea un nuovo topic Kafka
crea_topic() {
    read -p "Inserisci il nome del nuovo topic: " topic_name
    esegui_comando_kafka "kafka-topics.sh --bootstrap-server localhost:9092 --topic $topic_name --create --partitions 1 --replication-factor 1"
}

# Funzione che fornisce informazioni su un topic esistente
info_topic() {
    echo "Ecco la lista dei topic presenti:"
    mostra_lista_topic
    read -p "Inserisci il nome del topic: " topic_name
    esegui_comando_kafka "kafka-topics.sh --bootstrap-server localhost:9092 --topic $topic_name --describe"
}

# Funzione che mostra la lista di tutti i topic disponibili
mostra_lista_topic() {
    esegui_comando_kafka "kafka-topics.sh --list --bootstrap-server localhost:9092"
}



# Funzione che elimina un topic esistente
elimina_topic() {
    echo "Ecco la lista dei topic presenti:"
    mostra_lista_topic
    read -p "Inserisci il nome del topic da eliminare: " topic_name
    esegui_comando_kafka "kafka-topics.sh --delete --bootstrap-server localhost:9092 --topic $topic_name"
}

# Funzione che legge i messaggi di un topic in tempo reale
leggi_messaggi() {
    echo "Ecco la lista dei topic presenti:"
    mostra_lista_topic
    read -p "Inserisci il nome del topic da leggere: " topic_name
    echo "Lettura in real-time dei messaggi. Per uscire dalla lettura eseguire CTRL-C."
    esegui_comando_kafka "kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic $topic_name --from-beginning"
}

# Menu principale
while true; do
    clear
    echo """
 __  _   ____  _____  __  _   ____  
|  |/ ] /    ||     ||  |/ ] /    |
|  ' / |  o  ||   __||  ' / |  o  |
|    \ |     ||  |_  |    \ |     |
|     \|  _  ||   _] |     \|  _  |
|  .  ||  |  ||  |   |  .  ||  |  |
|__|\_||__|__||__|   |__|\_||__|__|                  
    """
    echo "===================================="
    echo "Seleziona l'operazione:"
    echo "1. Avvia container Kafka"
    echo "2. Ferma container Kafka"
    echo "3. Entra nel container Kafka"
    echo "4. Crea un nuovo topic"
    echo "5. Lista dei topic"
    echo "6. Ottieni informazioni su un topic"
    echo "7. Elimina un topic"
    echo "8. Leggi i messaggi di un topic"
    echo " "
    echo "0. Esci"
    echo "===================================="
    read -p "Scegli un'opzione: " scelta

    case $scelta in
        1) avvia_container_kafka ;;
        2) ferma_container_kafka ;;
        3) entra_nel_container ;;
        4) crea_topic ;;
        5) mostra_lista_topic ;;
        6) info_topic ;;
        7) elimina_topic ;;
        8) leggi_messaggi ;;
        0) echo "Uscita dal programma. Ciao! (´• ω •)ﾉ"; exit 0 ;;
        *) echo "Opzione non valida. Riprova." ;;
    esac
    read -p "Premi Invio per continuare..."
done