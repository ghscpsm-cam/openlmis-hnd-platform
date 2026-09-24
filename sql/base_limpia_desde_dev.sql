-- Genera la base limpia de Honduras a partir de una copia de DEV:
-- conserva los datos maestros y deja solo el usuario admin; borra transacciones,
-- lotes, notificaciones enviadas y usuarios de prueba.
-- TRUNCATE sin CASCADE: si falta una tabla dependiente, falla en vez de borrar de más.
-- NUNCA ejecutar sobre una base en uso: solo sobre una copia restaurada.
\set ON_ERROR_STOP on
BEGIN;

-- Stock: eventos, tarjetas, saldos e inventarios físicos
TRUNCATE
  stockmanagement.stock_event_line_items,
  stockmanagement.stock_events,
  stockmanagement.calculated_stocks_on_hand,
  stockmanagement.stock_card_line_items,
  stockmanagement.stock_cards,
  stockmanagement.physical_inventory_line_item_adjustments,
  stockmanagement.physical_inventory_line_items,
  stockmanagement.physical_inventories;

-- Requisiciones (stock_adjustment_reasons es una copia por requisición, no configuración)
TRUNCATE
  requisition.stock_adjustments,
  requisition.previous_adjusted_consumptions,
  requisition.requisition_line_items,
  requisition.requisition_permission_strings,
  requisition.requisitions_previous_requisitions,
  requisition.stock_adjustment_reasons,
  requisition.available_products,
  requisition.rejections,
  requisition.status_messages,
  requisition.status_changes,
  requisition.requisitions;

-- Órdenes, envíos y comprobantes de entrega
TRUNCATE
  fulfillment.proof_of_delivery_line_items,
  fulfillment.proofs_of_delivery,
  fulfillment.shipment_line_items,
  fulfillment.shipments,
  fulfillment.shipment_draft_line_items,
  fulfillment.shipment_drafts,
  fulfillment.status_messages,
  fulfillment.status_changes,
  fulfillment.order_line_items,
  fulfillment.orders;

-- Notificaciones ya enviadas o pendientes
TRUNCATE
  notification.notification_messages,
  notification.pending_notifications,
  notification.notifications;

-- Lotes de prueba
DELETE FROM referencedata.lots;

-- Usuarios de prueba: se conserva solo admin
CREATE TEMP TABLE usuarios_prueba AS
  SELECT id FROM referencedata.users WHERE username <> 'admin';

UPDATE referencedata.price_changes SET authorid = (SELECT id FROM referencedata.users WHERE username = 'admin')
  WHERE authorid IN (SELECT id FROM usuarios_prueba);
DELETE FROM referencedata.system_notifications WHERE authorid IN (SELECT id FROM usuarios_prueba);
DELETE FROM referencedata.right_assignments WHERE userid IN (SELECT id FROM usuarios_prueba);
DELETE FROM referencedata.role_assignments  WHERE userid IN (SELECT id FROM usuarios_prueba);
DELETE FROM referencedata.users             WHERE id     IN (SELECT id FROM usuarios_prueba);

DELETE FROM notification.digest_subscriptions      WHERE usercontactdetailsid IN (SELECT id FROM usuarios_prueba);
DELETE FROM notification.email_verification_tokens WHERE usercontactdetailsid IN (SELECT id FROM usuarios_prueba);
DELETE FROM notification.postpone_message          WHERE userid IN (SELECT id FROM usuarios_prueba);
DELETE FROM notification.user_contact_details      WHERE referencedatauserid IN (SELECT id FROM usuarios_prueba);

DELETE FROM auth.password_reset_registries           WHERE userid IN (SELECT id FROM usuarios_prueba);
DELETE FROM auth.password_reset_tokens               WHERE userid IN (SELECT id FROM usuarios_prueba);
DELETE FROM auth.auth_users                          WHERE id     IN (SELECT id FROM usuarios_prueba);
TRUNCATE auth.unsuccessful_authentication_attempts;

-- Verificación: si algo quedó, se revierte todo
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM (VALUES
      ((SELECT count(*) FROM stockmanagement.stock_cards), 'stock_cards'),
      ((SELECT count(*) FROM requisition.requisitions), 'requisitions'),
      ((SELECT count(*) FROM fulfillment.orders), 'orders'),
      ((SELECT count(*) FROM referencedata.lots), 'lots'),
      ((SELECT count(*) FROM referencedata.users WHERE username <> 'admin'), 'usuarios_no_admin'),
      ((SELECT count(*) FROM auth.auth_users WHERE username <> 'admin'), 'auth_no_admin')
    ) v(n, what)
  LOOP
    IF r.n <> 0 THEN RAISE EXCEPTION 'Quedaron % filas en %', r.n, r.what; END IF;
  END LOOP;
  IF (SELECT count(*) FROM referencedata.users WHERE username = 'admin') <> 1 THEN
    RAISE EXCEPTION 'No quedó el usuario admin';
  END IF;
END $$;

COMMIT;
