# Ranked Choice

# About

With a US election coming up, we started thinking about elections and how... well they suck. Most governments follow a "1 person 1 vote" style voting, which ultimately [leads to a 2 party system](https://www.youtube.com/watch?v=qf7ws2DF-zk). So, for our project, we decided to implement a ranked choice on-chain voting mechanism! 

# Known Issues

- In `_selectPresidentRecursive` there is an issue where if two candidates are tied, whoever was earlier in the list is dropped. This is known, and we are OK with it.
- There are other issues with this style of voting, like for example, in some cases a candidate who does worse will win. You can see a [longer explainer here.](https://www.youtube.com/watch?v=qf7ws2DF-zk)