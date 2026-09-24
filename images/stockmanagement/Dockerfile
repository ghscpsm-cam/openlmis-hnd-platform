# Stockmanagement oficial de OpenLMIS con los reportes de stock en español (Honduras).
# Solo cambian 4 plantillas jrxml dentro de service.jar; todo lo demás es la imagen oficial.
# Se construye en el propio servidor durante la instalación (no requiere registro de imágenes):
#   docker build -t openlmis-hnd-stockmanagement:5.3.0-hnd.1 images/stockmanagement
ARG BASE_IMAGE=openlmis/stockmanagement:5.3.0

FROM ${BASE_IMAGE} AS base

FROM python:3.12-alpine AS patch
WORKDIR /work
COPY --from=base /service.jar service.jar
COPY replace_zip_entry.py .
COPY templates/ templates/
# replace_zip_entry conserva la compresión original de cada entrada: Spring Boot exige
# que los jars de BOOT-INF/lib queden sin comprimir.
RUN for t in stockCard stockCardSummary physicalInventory physicalinventoryLines; do \
      python3 replace_zip_entry.py service.jar templates/$t.jrxml BOOT-INF/classes/jasperTemplates/$t.jrxml; \
    done \
 && chmod 664 service.jar

FROM ${BASE_IMAGE}
COPY --from=patch /work/service.jar /service.jar
