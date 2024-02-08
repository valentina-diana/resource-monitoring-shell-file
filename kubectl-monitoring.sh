#!/bin/bash

# Funcție pentru a verifica utilizarea resurselor pentru un anumit pod
check_pod_resource_usage() {
    local pod_name=$1
    local resource_type=$2
    local threshold=$3

    echo "Verificare utilizare $resource_type pentru pod-ul $pod_name..."

    # Obține utilizarea resurselor pentru un anumit pod
    local current_usage=$(kubectl top pod "$pod_name" --namespace=default | grep -v "POD" | awk '{print $2}')
    local current_usage2=$(kubectl top pod "$pod_name" --namespace=default | grep -v "POD" | awk '{print $3}')

    echo "current_usage: $current_usage" #CPU
    echo "current_usage2: $current_usage2" #Memory

    # Extragere valoare numerică
    local usage_value=$(echo "$current_usage" | sed 's/[^0-9]*//g') #Se ia valoarea pt CPU
    local usage_value2=$(echo "$current_usage2" | sed 's/[^0-9]*//g') #Se ia valoarea pt Memory


         echo "usage_value: $usage_value"
         echo "usage_value2: $usage_value2"
         


    # Verifică dacă utilizarea depășește pragul
    if [ "$resource_type" == "CPU" ]; then
        if [ -n "$usage_value" ] && [ "$(echo "$usage_value >= $threshold" | bc)" -eq 1 ]; then
            local alert_message="ALERT: Utilizarea $resource_type pentru pod-ul $pod_name depășește pragul de $threshold core."
        else
            local alert_message="Utilizare $resource_type pentru pod-ul $pod_name în limita normală."
        fi
    elif [ "$resource_type" == "memorie" ]; then
        if [ -n "$usage_value2" ] && [ "$(echo "$usage_value2 >= $threshold" | bc)" -eq 1 ]; then
            local alert_message="ALERT: Utilizarea $resource_type pentru pod-ul $pod_name depășește pragul de $threshold MiB."
        else
            local alert_message="Utilizare $resource_type pentru pod-ul $pod_name în limita normală."
        fi
    fi

    echo "$alert_message"
    echo "$(date): $alert_message" >> monitor_alerts.log

}

# Afișează instrucțiuni pentru utilizator
echo "Introduceți numele pod-ului pe care doriți să îl monitorizați:"
read pod_name

# Verifica dacă numele podului nu a fost specificat
if [ -z "$pod_name" ]; then
    echo "Eroare: Numele pod-ului nu a fost specificat."
    exit 1
fi

# Verifica dacă pod-ul exista in cluster
if ! kubectl get pod "$pod_name" --namespace=default &> /dev/null; then
    echo "Eroare: Pod-ul cu numele $pod_name nu există în cluster."
    exit 1
fi

echo "Alegeți resursa pe care doriți să o monitorizați pentru pod-ul $pod_name:"
echo "1. CPU"
echo "2. Memorie"

read resource_option

case $resource_option in
    1)
        resource_type="CPU"
       # threshold=200 # Setează pragul pentru CPU la 200 core(pt a da mesaj de alerta - pt pod-ul high-memory-pod(CPU=466milicore))
        threshold=500 # Setează pragul pentru CPU la 500 milicore(pt a NU da mesaj de alerta - pt pod-ul high-memory-pod(CPU=466milicore))
        ;;
    2)
        resource_type="memorie"
        threshold=2 # Setează pragul pentru memorie la 2 MiB(pt a da mesaj de alert- pod-ul high-cpu-pod(Memory=3Mi))
       # threshold=4 # Setează pragul pentru memorie la 4 MiB(pt a NU da mesaj de alert- pt pod-ul high-cpu-pod(Memory=3Mi))
       # threshold=6 # Seteaza pragul pt memorie la 6 MiB(pt a da mesaj de alerta - pt pod-ul mypod(Memory=7Mi))
       # threshold=7 # Seteaza pragul pt memorie la 7 MiB(pt a da mesaj de alerta - pt pod-ul mypod)
       # threshold=8 # Seteaza pragul pt memorie la 8 MiB(pt a NU da mesaj de alerta - pt pod-ul mypod)

        ;;
    *)
        echo "Opțiune invalidă"
        exit 1
        ;;
esac

check_pod_resource_usage "$pod_name" "$resource_type" "$threshold"