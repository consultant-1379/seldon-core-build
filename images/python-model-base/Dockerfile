#
# COPYRIGHT Ericsson 2022
#
#
#
# The copyright to the computer program(s) herein is the property of
#
# Ericsson Inc. The programs may be used and/or copied only with written
#
# permission from Ericsson Inc. or in accordance with the terms and
#
# conditions stipulated in the agreement/contract under which the
#
# program(s) have been supplied.
#

ARG USER_ID=237828
ARG CBOS_VERSION
ARG RELEASE_VERSION
ARG BUILD_DATE
ARG CBO_REPO_URL=https://arm.sero.gic.ericsson.se/artifactory/proj-ldc-repo-rpm-local/common_base_os/sles/${CBOS_VERSION}
ARG CBO_HEADERS=https://arm.sero.gic.ericsson.se/artifactory/proj-ldc-repo-rpm-local/common_base_os/sles/${CBOS_VERSION}_devel
ARG CBO_DEVEL=https://arm.sero.gic.ericsson.se/artifactory/proj-ldc-repo-rpm-local/adp-dev/adp-build-env/${CBOS_VERSION}
ARG MC_VERSION=RELEASE.2023-01-28T20-29-38Z

# BEGIN_BASE
FROM armdocker.rnd.ericsson.se/proj-ldc/common_base_os_release/sles:${CBOS_VERSION} as base
ARG CBOS_VERSION
ARG CBO_REPO_URL
ARG CBO_HEADERS
ARG CBO_DEVEL

RUN set -ex                                                                                                                \
    && zypper ar -C -G -f $CBO_REPO_URL?ssl_verify=no     COMMON_BASE_OS_SLES_REPO                                          \
    && zypper ar -C -G -f $CBO_HEADERS?ssl_verify=no CBO_HEADERS                                                           \
    && zypper ar -C -G -f $CBO_DEVEL?ssl_verify=no CBO_DEVEL                                                               \
    && zypper install --no-confirm curl wget xz jq zip python311 python311 python311-pip                                   \
    && ln -s /usr/bin/python3.11 /usr/bin/python3                                                                          \
    && python3 -m pip install --no-cache-dir --upgrade pip                                                                  \
    && python3 -m pip install --no-cache-dir --upgrade pipenv setuptools wheel                                              \
    && update-ca-certificates                                                                                               \
    && curl -L -o /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/archive/mc.${MC_VERSION}                \
    && chmod +x /usr/local/bin/mc                                                                                           \
    && zypper clean --all                                                                                                   \
    && zypper rr COMMON_BASE_OS_SLES_REPO CBO_HEADERS CBO_DEVEL                                                              

# BEGIN_RUNTIME
FROM base as python-runtime
ARG CBOS_VERSION
ARG BUILD_DATE
ARG PYTHON_VERSION
ARG RELEASE_VERSION
ARG USER_ID

ENV PYTHONUTF8 1    
RUN set -ex;                                                                       \
    echo "$USER_ID:x:$USER_ID:$USER_ID::/nonexistent:/bin/false" >> /etc/passwd;   \
    echo "$USER_ID:!::0:::::" >> /etc/shadow;                                      \
    echo "$USER_ID:x:$USER_ID:" >> /etc/group;                                     \
    mkdir -p /home/mxe;                                                            \
    chown $USER_ID:0 /home/mxe

USER $USER_ID
WORKDIR /home/mxe
ENV PATH /home/mxe/bin:/home/mxe/.local/bin:$PATH
CMD [ "/usr/local/bin/python3" ]
# END_RUNTIME

# MODEL RUNTIME
FROM python-runtime as model-runtime
ARG CBOS_VERSION
ARG COMMIT
ARG BUILD_DATE
ARG PYTHON_VERSION
ARG APP_VERSION
ARG SELDON_CORE_VERSION
ARG IMAGE_PRODUCT_NUMBER
ARG USER_ID
ARG RSTATE

LABEL os.name="CBO"
LABEL os.version=${CBOS_VERSION}
LABEL python.version=${PYTHON_VERSION}
LABEL seldon.core.version=${SELDON_CORE_VERSION}
LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.description="Base Model Image for Python using Common Base OS"
LABEL org.opencontainers.image.title="Base Model image for Python"
LABEL org.opencontainers.image.version=${APP_VERSION}
LABEL org.opencontainers.image.vendor="Ericsson"
LABEL org.opencontainers.image.revision=$COMMIT
LABEL com.ericsson.product-revision=$RSTATE
LABEL com.ericsson.product-number=$IMAGE_PRODUCT_NUMBER
LABEL com.ericsson.product-3pp-name="seldon-core"
LABEL com.ericsson.product-3pp-version=${SELDON_CORE_VERSION}

COPY constraints.txt /tmp/constraints.txt
COPY stdout/stdout-redirect /opt/stdout-redirect

USER root 
RUN set -e                                                                                               \
    && python3 -m pip install --no-cache-dir "Cython<3.0" PyYAML==5.4.1 --no-build-isolation             \
    && python3 -m pip install --no-cache-dir seldon-core==${SELDON_CORE_VERSION} -c /tmp/constraints.txt \
    && rm /tmp/constraints.txt                                                                           \
    && find /usr/local -type d -name "__pycache__" -prune -exec rm -rf '{}' +
USER $USER_ID

# BEGIN_TRAINING_RUNTIME
FROM python-runtime as training-runtime
ARG COMMON_BASE_OS_VERSION
ARG BUILD_DATE
ARG PYTHON_VERSION
ARG RELEASE_VERSION

ENV PYTHONUTF8 1
LABEL os.name="CBO"
LABEL os.version=${COMMON_BASE_OS_VERSION}
LABEL python.version=${PYTHON_VERSION}
LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.description="Base Training Image for Python using Common Base OS"
LABEL org.opencontainers.image.title="Base Training image for Python"
LABEL org.opencontainers.image.revision=1
LABEL org.opencontainers.image.version=${RELEASE_VERSION}
LABEL org.opencontainers.image.vendor="Ericsson"
    
# END_RUNTIME