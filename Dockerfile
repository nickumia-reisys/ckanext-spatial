FROM openknowledge/ckan-dev:2.9

COPY . /app
WORKDIR /app

RUN apk add --no-cache \
          geos \
          geos-dev \
          proj-util \
          proj-dev \
          libxml2 \
          libxslt \
          gcc \
          libxml2-dev \
          libxslt-dev \
          python3-dev

#RUN git clone https://github.com/ckan/ckanext-harvest
#RUN cd ckanext-harvest && \
#        pip install -r pip-requirements.txt && \
#        pip install -r dev-requirements.txt && \
#        pip install -e .
RUN pip install -r requirements.txt -e .

RUN sed -i -e 's/use = config:.*/use = config:\/srv\/app\/src\/ckan\/test-core.ini/' test.ini

RUN . /usr/lib/python3.8/venv/scripts/common/activate && \
        cd /app && \
        python3 setup.py install
