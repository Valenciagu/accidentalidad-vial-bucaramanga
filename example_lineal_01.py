import numpy as np
import matplotlib.pyplot as plt

# Tamaño de los datos
n = np.arange(1, 1000001)

# Una operación constante
operaciones = np.ones(len(n))

plt.figure(figsize=(10, 6))
plt.plot(n, operaciones, label="O(1)")

plt.title("Sistema de acceso directo - Complejidad O(1)")
plt.xlabel("Cantidad de empleados")
plt.ylabel("Operaciones")

plt.legend()
plt.grid(True)
plt.show()