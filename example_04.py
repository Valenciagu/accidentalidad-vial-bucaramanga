import random
import time
import math
import matplotlib.pyplot as plt


# ==========================================
# ALGORITMO MERGE
# ==========================================

def merge(izquierda, derecha):
    resultado = []

    i = 0
    j = 0

    # Comparar los elementos de ambas listas
    while i < len(izquierda) and j < len(derecha):

        # Orden descendente
        if izquierda[i] >= derecha[j]:
            resultado.append(izquierda[i])
            i += 1
        else:
            resultado.append(derecha[j])
            j += 1

    # Agregar los elementos restantes
    resultado.extend(izquierda[i:])
    resultado.extend(derecha[j:])

    return resultado


# ==========================================
# ALGORITMO MERGE SORT
# ==========================================

def merge_sort(lista):

    # Caso base
    if len(lista) <= 1:
        return lista

    # Dividir la lista
    medio = len(lista) // 2

    # Ordenar recursivamente cada mitad
    izquierda = merge_sort(lista[:medio])
    derecha = merge_sort(lista[medio:])

    # Combinar las dos listas ordenadas
    return merge(izquierda, derecha)


# ==========================================
# TAMAÑOS DE PRUEBA
# ==========================================

tamanos = [
    10000
]

tiempos = []
operaciones_teoricas = []


# ==========================================
# MEDIR TIEMPOS
# ==========================================

for n in tamanos:

    # Simular las compras realizadas por los clientes
    compras_clientes = [
        random.randint(100000, 5000000)
        for _ in range(n)
    ]

    # Iniciar cronómetro
    inicio = time.perf_counter()

    # Ejecutar Merge Sort
    ranking = merge_sort(compras_clientes)

    # Finalizar cronómetro
    fin = time.perf_counter()

    # Calcular tiempo de respuesta
    tiempo_respuesta = fin - inicio

    tiempos.append(tiempo_respuesta)

    # Calcular valor teórico n log2(n)
    operaciones = n * math.log2(n)
    operaciones_teoricas.append(operaciones)

    # Mostrar resultados en consola
    print("-" * 50)
    print(f"Cantidad de clientes: {n}")
    print(f"Tiempo de respuesta: {tiempo_respuesta:.8f} segundos")
    print(f"Tiempo en milisegundos: {tiempo_respuesta * 1000:.4f} ms")
    print(f"Operaciones teóricas n log₂(n): {operaciones:.2f}")


# ==========================================
# MOSTRAR UN EJEMPLO DEL RANKING
# ==========================================

print("\n" + "=" * 50)
print("EJEMPLO DE RANKING DE CLIENTES")
print("=" * 50)

ejemplo_compras = [
    500000,
    2000000,
    800000,
    1200000,
    3500000
]

ranking_ejemplo = merge_sort(ejemplo_compras)

print("Compras originales:")
print(ejemplo_compras)

print("\nRanking de mayor a menor:")
print(ranking_ejemplo)


# ==========================================
# GRÁFICA 1: TIEMPO REAL DE RESPUESTA
# ==========================================

plt.figure(figsize=(10, 6))

plt.plot(
    tamanos,
    tiempos,
    marker="o",
    label="Tiempo real"
)

plt.title("Tiempo de respuesta de Merge Sort")
plt.xlabel("Cantidad de clientes (n)")
plt.ylabel("Tiempo de respuesta (segundos)")

plt.legend()
plt.grid(True)
plt.show()


# ==========================================
# GRÁFICA 2: CRECIMIENTO TEÓRICO O(n log n)
# ==========================================

plt.figure(figsize=(10, 6))

plt.plot(
    tamanos,
    operaciones_teoricas,
    marker="o",
    label="O(n log n)"
)

plt.title("Crecimiento teórico de Merge Sort")
plt.xlabel("Cantidad de clientes (n)")
plt.ylabel("Operaciones aproximadas")

plt.legend()
plt.grid(True)
plt.show()