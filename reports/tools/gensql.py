import binascii
R = [  # id, archivo, nombre, descripción
 ('5ccbdfe1-594f-4830-960d-801dabf36566','cce_alert_history','Historial de alertas de cadena de frío','Alertas de monitoreo remoto de temperatura de un equipo en los últimos 30 días'),
 ('7f50dac3-3768-4588-9eeb-f992f5d524fc','facility_assignment_configuration_errors','Errores de configuración de asignación de establecimientos','Establecimientos sin programas, roles o nodo supervisor asignados'),
 ('56704147-b795-42c3-a81a-995d8df18a19','periodic_stock_on_hand_summary','Resumen periódico de existencias','Existencia inicial, movimientos y existencia final por producto en un periodo'),
 ('583ccc35-88b7-48a8-9193-6c4857d3ff60','local_fulfillment_pick_pack_list','Lista de selección y empaque','Productos, lotes y cantidades a despachar de un borrador de envío'),
 ('1fd4208c-6840-4925-a1f6-5770e8fb3e97','stock_on_hand','Existencias en mano','Existencias por establecimiento, producto y lote a una fecha'),
]
D = {'Inventory Item ID':'ID del equipo','Shipment Draft ID':'ID del borrador de envío','Start Date':'Fecha de inicio','End Date':'Fecha de fin',
     'Facility':'Establecimiento','Program':'Programa','Product':'Producto','Date':'Fecha','Expired Products':'Productos vencidos',
     'Facility Type':'Tipo de establecimiento','Geographic Zone':'Zona geográfica'}
def hx(f): return binascii.hexlify(open('out/%s.ser'%f,'rb').read()).decode()
q=lambda s: "'"+s.replace("'","''")+"'"
o=['-- Reportes estándar de OpenLMIS en español (Honduras). Idempotente: se aplica en cada up/restore.',
   '-- Plantillas compiladas con las librerías de openlmis/report:1.5.0 y openlmis/stockmanagement:5.3.0',
   '-- (JasperReports 6.5.1) a partir de reports/es/*.jrxml. Se conservan los IDs: la UI abre',
   '-- la lista de selección y empaque por su ID fijo.',
   'BEGIN;']
for i,f,n,d in R:
    o.append("UPDATE report.jasper_templates SET name = %s, description = %s, data = decode('%s', 'hex') WHERE id = '%s';" % (q(n),q(d),hx(f),i))
ids=",".join("'%s'"%r[0] for r in R)
o.append("UPDATE report.template_parameters SET displayname = CASE displayname %s ELSE displayname END WHERE templateid IN (%s);" %
         (" ".join("WHEN %s THEN %s"%(q(a),q(b)) for a,b in D.items()), ids))
o.append("UPDATE stockmanagement.jasper_templates SET data = decode('%s', 'hex') WHERE name = 'Print PI';" % hx('physicalInventory'))
o.append('COMMIT;')
open('../db-fixes/002_reportes_es.sql','w',encoding='utf-8').write("\n".join(o)+"\n")
print('ok')
