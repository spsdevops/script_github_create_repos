<img src="https://www.spsolutions.com.mx/assets/img/SPS_logo.png" align="right" height="90" />

> ℹ️ Si requieres ayuda para definir tu proceso de CI/CD puedes levantar un issue en este repositorio o contactarnos en la siguiente liga: https://www.spsolutions.com.mx/#Contacto 

# crear-repos

<!-- TABLE DE CONTENIDO -->

<details open="open">
  <summary>Tabla de contenido</summary>
  <ol>
    <li><a href="#🧬-acerca-de-la-interfaz">Acerca de</a></li>
    <li><a href="#📋-requisitos">Requisitos</a></li>
    <li><a href="#🚦-uso">Uso</a></li>
  </ol>
</details>

## 🧬 Acerca de

Este script permite crear múltiples repositorios el detalle de la configuración: organización, nombre del repositorio y permisos se obtienen de un CSV.

- Cada linea del archivo CSV crea y configura un repositorio.
- Todos los repositorios tienen 3 ambientes: develop, preprod, production.
- Se pueden agregar aprobadores de despliegue en los ambientes preprod y production.
- Se debe colocar al menos un equipo con permisos de administración y al menos un equipo con permisos de escritura.
- Es posible crear repositorios publicos, privados e internos.

El script es muy simple pero puede ser refactorizado para utilizar funciones y hacerlo más mantenible.

## 📋 Requisitos

1. [Instalar el CLI de Github](https://cli.github.com/manual/installation)
   - Iniciar sesión `gh auth login`
2. [Powershell 5.1](https://docs.microsoft.com/en-us/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-windows-powershell-5-1)
   - Usualmente es la versión que viene instalada por defecto en Windows 10. Puedes validarlo ejecutando `Get-Host | Select-Object Version` en una terminal de PowerShell

## 🚦 Uso

1. Clonar este repositorio o descargalo como ZIP
2. Dentro de la carpeta [scripts/crear-repos](scripts/crear-repos) se encuentra un archivo [crear-repos.csv](scripts/crear-repos/crear-repos.csv)
3. Editar el archivo con los repositorios a crear. Las columan son:

| Columna              | Descripción                                                                                                                                                                                                                                  |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| *organizacion*       | Nombre de la organización en la que se creará el repositorio (El usuario configurado en el CLI de Github debe tener permisos para crear repositorios)                                                                                        |
| *repositorio*        | Nombre del repositorio a crear                                                                                                                                                                                                               |
| *tipo*               | Tipo de repositorio a crear (private, internal y public)                                                                                                                                                                                     |
| *descripcion*        | Descripción que tendrá el repositorio a crear, no puede incluir comas.                                                                                                                                                                                                |
| *admin_list*         | Equipos con permisos de administración sobre el repositorio, si es más de un equipo debe ir separado por un &.                                                                                                                               |
| *write_list*         | Equipos con permisos de escritura sobre el repositorio, si es más de un equipo debe ir separado por un &.                                                                                                                                    |
| *read_list*          | Equipos con permisos de lectura sobre el repositorio, si es más de un equipo debe ir separado por un &.                                                                                                                                      |
| *aprobador_pre_list* | Equipos que pueden aprobar un despliegue a _preprod_, si es más de un equipo debe ir separado por un &. Los aprobadores deben tener permisos al menos de lectura. Los aprobadores deben estar también en admin_list, write_list o read_list. |
| aprobador_prod_list  | Equipos que pueden aprobar un despliegue a _production_, si es más de un equipo debe ir separado por un &. Los aprobadores deben estar también en admin_list, write_list o read_list.                                                        |

4. Abrir una terminal de PowerShell.

5. Muevete a la carpeta del script y ejecutalo.
   
   ```
   cd <Ruta del repositorio SAUTO_CICD>/scripts/crear-repos
   .\crear-repos.ps1
   ```

> Si tienes problemas para diagnosticar un error se puede agregar el parametro -Debug al ejecutar el script.

```
.\crear-repos.ps1 -Debug
```

6. Una vez terminado se genera un archivo de reporte con el nombre reporte_yyyyMMddTHHmmssZ.csv_ con la URL de los repositorios y un mensaje de error si es que ocurrio alguno.

## Links

* [Github CLI manual](https://cli.github.com/manual/index)
* [Github REST API](https://docs.github.com/en/rest)
* [Github Repositorios](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories)
