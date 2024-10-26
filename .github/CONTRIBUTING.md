# Contributors Guide

## Welcome to the IRL Project!

IRL is an open-source project aimed at creating an AI-powered augmented memory assistant and digital advocate. Whether you're a Swift wizard or Python pro, or if you enjoy working with cloud infrastructure, there's a space for you to contribute! This guide will help you get started with contributing to the project.

---

## Table of Contents

- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Coding Guidelines](#coding-guidelines)
- [License](#license)
- [Reporting Issues](#reporting-issues)
- [Community and Support](#community-and-support)

---

## Getting Started

Before you start contributing, make sure to set up your local environment:

- **Swift**: The app is primarily written in Swift, so if you're contributing to the iOS app, please ensure you're familiar with iOS development.
- **Python**: The backend leverages Python, and if you're working on this, you'll need experience with FastAPI and websockets.
- **Hetzner and Distributed Systems**: Our servers are distributed across nodes, connected via Tailscale. Contributions to cloud infrastructure should consider node efficiency and network security.
- **Next.js/React**: Our website is built with React and Next.js (version 14). Frontend contributors should be comfortable with these technologies, along with TypeScript.

For all contributors, we recommend reviewing the codebase and setting up your environment using the provided instructions in the project README file.

---

## How to Contribute

1. **Fork the Repository**: Start by forking the project repository and cloning it to your local machine.
   
2. **Create a Branch**: Create a feature or bugfix branch that reflects the nature of your contribution. For example:
    - `feature/add-new-ai-module`
    - `fix/resolve-async-issue`

3. **Make Your Changes**: Ensure your code follows the coding guidelines outlined below.

4. **Test Your Code**: Thoroughly test your contributions. If you’re contributing to the app, check for smooth interaction between SwiftUI and backend services.

5. **Commit**: Write clear and concise commit messages:
    - `git commit -m "Add augmented memory feature to backend"`
  
6. **Pull Request**: Submit a pull request to the main repository with a detailed description of your changes and their intent. Link any relevant issues or projects.

---

## Coding Guidelines

To maintain code quality, follow these guidelines:

- **Swift**: Ensure your Swift code is optimized and adheres to Apple's best practices. Try to minimize memory consumption, as the app runs background tasks.
  
- **Python**: Follow PEP 8 guidelines. Backend contributions should focus on improving websocket management, scaling across nodes, and handling concurrency efficiently.

- **React/Next.js**: Use TypeScript and ensure components are well-typed. Be mindful of performance, especially in rendering large datasets in the UI.

- **Testing**: Add tests where appropriate. For Swift, leverage XCTest for unit tests. For Python, pytest is recommended. In the frontend, ensure Next.js page components are tested with Jest or React Testing Library.

- **Tailscale Configuration**: If you contribute to the distributed infrastructure, ensure you thoroughly test node-to-node communication and provide updated documentation if necessary.

---

## License

Contributions to this project are licensed under the custom license detailed in the repository. Key terms include:

1. **Usage Rights**: You are free to use and modify the code, but redistribution is restricted.
2. **Contributions**: By contributing, you agree that your work will be licensed under the same terms.

For a complete overview, review the full license text in the repository.

---

## Reporting Issues

- **Found a Bug?** Check the existing issues before creating a new one. If the issue already exists, contribute to the conversation instead of duplicating.
- **Need a New Feature?** Submit a feature request through the issues section, ensuring it aligns with the project goals.

All issue tracking is handled through GitHub’s issues and projects tabs. Please tag your issues appropriately to help maintainers understand and prioritize them.

---

## Community and Support

Join the conversation and connect with other contributors!

- **Discussions**: Use the [Discussions](https://github.com/ebowwa/irl/discussions) section to ask questions or share ideas.
- **Support**: For technical support, visit the relevant issue or project subsection.

We welcome new contributors and hope this project becomes a learning and sharing experience for all involved!

---

Thanks for your interest in contributing to IRL! Let's build an amazing AI assistant together.
