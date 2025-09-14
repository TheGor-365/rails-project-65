.PHONY: env
env:
	@test -f .env || cp .env.example .env
	@echo "✔ Created/kept .env. Open it and set:"
	@echo "  GITHUB_CLIENT_ID=Ov23liZdnZre07G2jNKP"
	@echo "  GITHUB_CLIENT_SECRET=5f1c66634eb679990f23a1450fa81e6a909ed858"
