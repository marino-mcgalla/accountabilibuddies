#!/bin/bash

# Test runner script for AccountabiliBuddies
# This script provides easy commands to run different types of tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to run tests with coverage
run_tests_with_coverage() {
    print_status "Running tests with coverage..."
    flutter test --coverage
    
    if command -v lcov &> /dev/null; then
        print_status "Generating coverage report..."
        lcov --remove coverage/lcov.info \
            'lib/generated/*' \
            'lib/firebase_options.dart' \
            'lib/main.dart' \
            'test/*' \
            -o coverage/lcov.info
        
        genhtml coverage/lcov.info -o coverage/html
        print_success "Coverage report generated in coverage/html/"
    else
        print_warning "lcov not installed. Install with: brew install lcov"
    fi
}

# Function to run specific test types
run_unit_tests() {
    print_status "Running unit tests..."
    flutter test test/unit/
}

run_widget_tests() {
    print_status "Running widget tests..."
    flutter test test/widget/
}

run_integration_tests() {
    print_status "Running integration tests..."
    flutter test test/integration/
}

# Function to run all tests
run_all_tests() {
    print_status "Running all tests..."
    flutter test
}

# Function to run tests with watch mode
run_tests_watch() {
    print_status "Running tests in watch mode..."
    flutter test --watch
}

# Function to run tests with specific tags
run_tests_with_tags() {
    local tags=$1
    print_status "Running tests with tags: $tags"
    flutter test --tags "$tags"
}

# Function to analyze code quality
analyze_code() {
    print_status "Analyzing code..."
    flutter analyze
    
    if [ $? -eq 0 ]; then
        print_success "Code analysis passed!"
    else
        print_error "Code analysis failed!"
        exit 1
    fi
}

# Function to format code
format_code() {
    print_status "Formatting code..."
    dart format .
    print_success "Code formatted!"
}

# Function to run pre-commit checks
pre_commit_check() {
    print_status "Running pre-commit checks..."
    
    format_code
    analyze_code
    run_all_tests
    
    print_success "All pre-commit checks passed!"
}

# Function to show help
show_help() {
    echo "Test runner for AccountabiliBuddies"
    echo ""
    echo "Usage: ./test_runner.sh [command]"
    echo ""
    echo "Commands:"
    echo "  all           Run all tests"
    echo "  unit          Run unit tests only"
    echo "  widget        Run widget tests only"
    echo "  integration   Run integration tests only"
    echo "  coverage      Run tests with coverage"
    echo "  watch         Run tests in watch mode"
    echo "  tags <tags>   Run tests with specific tags"
    echo "  analyze       Analyze code quality"
    echo "  format        Format code"
    echo "  pre-commit    Run pre-commit checks"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./test_runner.sh all"
    echo "  ./test_runner.sh unit"
    echo "  ./test_runner.sh tags \"unit,fast\""
    echo "  ./test_runner.sh coverage"
}

# Main script logic
case "$1" in
    "all")
        run_all_tests
        ;;
    "unit")
        run_unit_tests
        ;;
    "widget")
        run_widget_tests
        ;;
    "integration")
        run_integration_tests
        ;;
    "coverage")
        run_tests_with_coverage
        ;;
    "watch")
        run_tests_watch
        ;;
    "tags")
        if [ -z "$2" ]; then
            print_error "Please specify tags to run"
            exit 1
        fi
        run_tests_with_tags "$2"
        ;;
    "analyze")
        analyze_code
        ;;
    "format")
        format_code
        ;;
    "pre-commit")
        pre_commit_check
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    "")
        print_warning "No command specified. Running all tests..."
        run_all_tests
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac