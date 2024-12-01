# Development directory shortcuts and auto-correction
#  source ~/caringmind/scripts/dev_aliases.sh
export CARINGMIND_ROOT="$HOME/caringmind"
export BACKEND_DIR="$CARINGMIND_ROOT/backend"
export FRONTEND_DIR="$CARINGMIND_ROOT/clients/caringmindWeb"

# Backend development aliases
alias backend="cd $BACKEND_DIR"
alias python="cd $BACKEND_DIR && python"
alias pip="cd $BACKEND_DIR && pip"
alias pytest="cd $BACKEND_DIR && pytest"
alias uvicorn="cd $BACKEND_DIR && uvicorn"

# Frontend development aliases
alias frontend="cd $FRONTEND_DIR"
alias npm="cd $FRONTEND_DIR && npm"
alias yarn="cd $FRONTEND_DIR && yarn"
alias react-scripts="cd $FRONTEND_DIR && react-scripts"
alias next="cd $FRONTEND_DIR && next"

# Development command wrapper function
dev() {
    case "$1" in
        "b" | "backend")
            cd "$BACKEND_DIR"
            ;;
        "f" | "frontend")
            cd "$FRONTEND_DIR"
            ;;
        *)
            echo "Usage: dev [b|backend|f|frontend]"
            ;;
    esac
}
