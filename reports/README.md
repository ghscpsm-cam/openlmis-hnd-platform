# Reportes en español (Honduras)

`es/` contiene las plantillas oficiales traducidas al español:

| Archivo | Origen | Dónde vive en OpenLMIS |
|---|---|---|
| `cce_alert_history.jrxml`, `facility_assignment_configuration_errors.jrxml`, `local_fulfillment_pick_pack_list.jrxml`, `periodic_stock_on_hand_summary.jrxml`, `stock_on_hand.jrxml` | openlmis-report v1.5.0 | `report.jasper_templates` (sección Reportes) |
| `physicalInventory.jrxml` | openlmis-stockmanagement v5.3.0 | `stockmanagement.jasper_templates` ("Print PI") |

Estas plantillas se guardan **compiladas** en la base de datos, así que se aplican con el
db-fix `db-fixes/002_reportes_es.sql`, que platform ejecuta en cada `up`/`restore`. El db-fix
actualiza las plantillas **conservando sus IDs**: la pantalla de despachos abre la lista de
selección y empaque por el ID fijo `583ccc35-...`, y subirlas por la API
(`/api/reports/templates/common`) las recrea con un ID nuevo.

Las plantillas de la Tarjeta de Almacén, el resumen de existencias y las líneas del inventario
físico van dentro de la imagen `openlmis-hnd-stockmanagement`, que se construye en el servidor desde `images/stockmanagement/`.

## Regenerar el db-fix después de cambiar un .jrxml

Compilar con las mismas librerías que usa el servicio (JasperReports 6.5.1 de las imágenes oficiales),
igual que hace el servicio: `JasperCompileManager.compileReport` + `ObjectOutputStream`.

```bash
# en un servidor con Docker, dentro de reports/
for svc in report:1.5.0 stockmanagement:5.3.0; do
  n=${svc%%:*}; c=$(docker create openlmis/$svc); docker cp $c:/service.jar $n.jar; docker rm $c
  python3 -c "import zipfile;z=zipfile.ZipFile('$n.jar');[z.extract(f,'$n-x') for f in z.namelist() if f.startswith(('BOOT-INF/lib/','BOOT-INF/classes/'))]"
done
mkdir -p out tool-r tool-s
docker run --rm -v "$PWD":/w -w /w --entrypoint sh openlmis/report:1.5.0 -c 'java -cp report-x/BOOT-INF/lib/ecj-4.4.2.jar org.eclipse.jdt.internal.compiler.batch.Main -1.8 -nowarn -cp report-x/BOOT-INF/lib/jasperreports-6.5.1.jar -d tool-r tools/Compile.java && cd es && java -cp "../tool-r:../report-x/BOOT-INF/classes:../report-x/BOOT-INF/lib/*" Compile cce_alert_history.jrxml ../out/cce_alert_history.ser facility_assignment_configuration_errors.jrxml ../out/facility_assignment_configuration_errors.ser local_fulfillment_pick_pack_list.jrxml ../out/local_fulfillment_pick_pack_list.ser periodic_stock_on_hand_summary.jrxml ../out/periodic_stock_on_hand_summary.ser stock_on_hand.jrxml ../out/stock_on_hand.ser'
docker run --rm -v "$PWD":/w -w /w --entrypoint sh openlmis/stockmanagement:5.3.0 -c 'java -cp stockmanagement-x/BOOT-INF/lib/ecj-4.4.2.jar org.eclipse.jdt.internal.compiler.batch.Main -1.8 -nowarn -cp stockmanagement-x/BOOT-INF/lib/jasperreports-6.5.1.jar -d tool-s tools/Compile.java && cd es && java -cp "../tool-s:../stockmanagement-x/BOOT-INF/classes:../stockmanagement-x/BOOT-INF/lib/*" Compile physicalInventory.jrxml ../out/physicalInventory.ser'
python3 tools/gensql.py
```
