# Changes v0.3.1 --> v0.3.5
## 1. Overview
[AggLayer v0.3.0](https://github.com/agglayer/protocol-research/blob/main/docs/ADRs/v0.3.0.md) added the support for a new consensus type that allows a chain to specify its own requirements. While the approach was valid to incorporate custom chains that verify its own state transition proof, it came with two major issues:

  - Reliance on a single address to submit certificates (ECDSA).
  - Potential soundness bugs with permissionless proof verification.

An update on the [consensus_type = 1](https://github.com/agglayer/protocol-research/blob/main/docs/ADRs/v0.3.0.md#generic-aggchains) is introduced in order to mitigate the aforementioned issues.

## 2. Motivation
Agglayer initially supported only `ECDSA`. Later, [CONSENSUS_TYPE = 1](https://github.com/agglayer/protocol-research/blob/main/docs/ADRs/v0.3.0.md) was introduced to provide networks with more flexibility.

This change enabled the use of a generic `aggchain-proof`, allowing chains to perform any state transition without modifying the pessimistic program.

However, production usage revealed new requirements, particularly around security and responsibility distribution. A significant single point of failure was identified in two components: [`aggOracle` and `aggSender`](https://github.com/agglayer/protocol-research/issues/161). This issue became especially critical when launching a chain holding a large amount of locked value, as no party was willing to operate a component bearing such responsibility.

Another option explored was to add a new `aggchain-proof` dedicated to ECDSA multisig (or BLS). While `aggchain-proof` offers flexibility and customizability, it increases integration complexity and imposes additional costs on Infrastructure Providers (IPs), as they would need to run yet another component. This discussion also raised the need for permissioned certificate submission to the `agglayer-node` to prevent potential exploits if a soundness issue occurs in the prover. Currently, sender verification is done at the infrastructure level, but a more robust solution would involve moving this verification to the pessimistic program itself.

The proposed approach aims to balance these considerations by introducing a hybrid solution implemented entirely in the pessimistic program. This eliminates the need for an additional `aggchain-proof` while enabling multiple signature verification to avoid relying on a single EOA.

The new design is modular, allowing chains to choose whether to use both features or only one—multisig and/or `sp1` verification. It also gives chains the option to rely on a default committee run by Polygon if desired.

This approach is also relevant for outpost chains, as discussed [here](https://github.com/agglayer/protocol-team-kanban/issues/645).

## 3. Specification
Specification can be found in the [agglayer specification repository](https://github.com/agglayer/specs/tree/main/specs).

!!! info
    The specification is in WIP [here](https://github.com/agglayer/specs/pull/45)