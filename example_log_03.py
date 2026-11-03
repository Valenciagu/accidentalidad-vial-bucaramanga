import numpy as np
import matplotlib.pyplot as plt


# Clientes de ejemplo, ordenados por total de compras.
clientes = [
	{"tipo": "A", "compras": 500000},
	{"tipo": "B", "compras": 800000},
	{"tipo": "C", "compras": 2000000},
]

ranking = sorted(clientes, key=lambda cliente: cliente["compras"], reverse=True)

print("Ranking de clientes:")
for posicion, cliente in enumerate(ranking, start=1):
	print(f"{posicion}. Tipo {cliente['tipo']}: ${cliente['compras']:,}")

# Ordenar n clientes mediante sort() tiene complejidad O(n log n).
n = np.arange(1, 100000001)
operaciones = n * np.log2(n)

plt.figure(figsize=(10, 6))
plt.plot(n, operaciones, label="O(n log n)")

plt.title("Ranking de clientes - Complejidad O(n log n)")
plt.xlabel("Cantidad de clientes")
plt.ylabel("Operaciones estimadas")

plt.legend()
plt.grid(True)
plt.show()
