.PHONY: setup dev dev-full infra sdlc monitoring qa design build test test-backend test-frontend test-e2e lint qa-security qa-accessibility qa-performance seed clean help

# ===== SETUP =====
setup:
	@echo "Creating service repositories..."
	@mkdir -p ../api-gateway ../auth-service ../cart-service ../product-service ../admin-service ../e-commerce-frontend

# ===== DOCKER =====
dev:
	docker compose --profile backend up --build

dev-full:
	docker compose --profile full up --build

infra:
	docker compose up postgres redis kafka jaeger

sdlc:
	docker compose --profile sdlc up

monitoring:
	docker compose --profile monitoring up

qa:
	docker compose --profile qa up

design:
	docker compose --profile design up

# ===== BUILD =====
build:
	cd ../api-gateway && ./mvnw clean package -DskipTests
	cd ../auth-service && ./mvnw clean package -DskipTests
	cd ../cart-service && ./mvnw clean package -DskipTests
	cd ../product-service && ./mvnw clean package -DskipTests
	cd ../order-management-api && ./mvnw clean package -DskipTests
	cd ../admin-service && ./mvnw clean package -DskipTests
	cd ../e-commerce-frontend && npm run build

# ===== TEST =====
test:
	@bash scripts/run-tests.sh

test-backend:
	cd ../api-gateway && ./mvnw test
	cd ../auth-service && ./mvnw test
	cd ../cart-service && ./mvnw test
	cd ../product-service && ./mvnw test
	cd ../order-management-api && ./mvnw test
	cd ../admin-service && ./mvnw test

test-frontend:
	cd ../e-commerce-frontend && npm run test

test-e2e:
	cd ../e-commerce-frontend && npx playwright test

# ===== LINT =====
lint:
	cd ../e-commerce-frontend && npm run lint
	cd ../api-gateway && ./mvnw checkstyle:check
	cd ../auth-service && ./mvnw checkstyle:check
	cd ../cart-service && ./mvnw checkstyle:check
	cd ../product-service && ./mvnw checkstyle:check
	cd ../admin-service && ./mvnw checkstyle:check

# ===== QA =====
qa-security:
	@bash scripts/security-scan.sh

qa-accessibility:
	cd ../e-commerce-frontend && npm run lighthouse

qa-performance:
	@bash scripts/load-tests.sh

# ===== SEED =====
seed:
	@bash scripts/seed-plane.sh
	@bash scripts/seed-bookstack.sh

# ===== CLEAN =====
clean:
	docker compose --profile full down -v --remove-orphans
	@echo "Cleaned all containers and volumes"

# ===== HELP =====
help:
	@echo "Available commands:"
	@echo "  make dev           - Start backend + infrastructure"
	@echo "  make dev-full      - Start everything"
	@echo "  make infra         - Start infrastructure only"
	@echo "  make sdlc          - Start SDLC tools (Plane + BookStack)"
	@echo "  make monitoring    - Start monitoring stack"
	@echo "  make qa            - Start QA tools (SonarQube + ZAP)"
	@echo "  make design        - Start design tools (Penpot)"
	@echo "  make build         - Build all services"
	@echo "  make test          - Run all tests"
	@echo "  make lint          - Run all linters"
	@echo "  make seed          - Populate SDLC tools"
	@echo "  make clean         - Stop and remove all containers"