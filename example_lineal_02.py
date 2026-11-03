import numpy as np
import matplotlib.pyplot as plt

# Tamaño de los datos
n = np.arange(1, 1000001)

# Datos de nómina de ejemplo y tasa de deducción.
salarios = np.linspace(1500000, 3000000, len(n))
tasa_deduccion = 0.10

# Se reserva el arreglo para evitar ampliarlo durante el ciclo.
registros = np.empty(
    len(n),
    dtype=[
        ("salario", "f8"),
        ("deduccion", "f8"),
        ("pago_final", "f8"),
    ],
)
operaciones = np.empty(len(n), dtype=np.int64)
total_operaciones = 0

for indice in range(len(n)):
	salario = salarios[indice]
	deduccion = salario * tasa_deduccion
	pago_final = salario - deduccion

	registros[indice] = (salario, deduccion, pago_final)
	total_operaciones += 4
	operaciones[indice] = total_operaciones

plt.figure(figsize=(10, 6))
plt.plot(n, operaciones, label="O(n)")

plt.title("Procesamiento de nómina - Complejidad O(n)")
plt.xlabel("Cantidad de empleados")
plt.ylabel("Operaciones acumuladas")

plt.legend()
plt.grid(True)
plt.show()