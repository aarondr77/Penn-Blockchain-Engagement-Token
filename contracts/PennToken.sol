pragma solidity ^0.5.00;

import "./ERC20.sol";

contract PennToken is ERC20 {

  enum eventState {CREATED, SIGNIN, CLOSED, REWARDED}
  enum rewardState {BROWSE, REDEEM, CLOSED}

  mapping (uint => mapping (address => bool)) attendance;
  mapping (uint => Event) events;
  mapping (uint => Reward) rewards;
  mapping (address => bool) owners;

  uint numEvents = 0;
  uint numRewards = 0;

  struct Event {
    uint EventID;
    eventState state;
    string description;
    uint rewardAmount;
    uint maxAttendees;
    address[] presentMembers;
  }

  struct Reward {
      uint RewardID;
      rewardState state;
      string description;
      uint price;
      uint numClaimed;
      uint maxClaimable;
  }

  modifier onlyOwners (address sender) {
      require(owners[sender], "not owner");
      _;
  }

  constructor () public {
      owners[msg.sender] = true;
  }

  function signIn(uint EventID) public {
    require(attendance[EventID][msg.sender] == false, "already signed in");
    require(events[EventID].state == eventState.SIGNIN, "not sign in period");
    attendance[EventID][msg.sender] = true;
    events[EventID].presentMembers.push(msg.sender);
  }

  function createNewEvent (string memory _description, uint _rewardAmount, uint _maxAttendees) public onlyOwners(msg.sender) {
      numEvents ++;
      address[] memory _presentMembers = new address[](_maxAttendees);
      events[numEvents] = Event ({
          EventID: numEvents,
          state: eventState.CREATED,
          description: _description,
          rewardAmount: _rewardAmount,
          maxAttendees: _maxAttendees,
          presentMembers: _presentMembers
      });

  }

  function openEvent (uint EventID) onlyOwners (msg.sender) public {
      events[EventID].state = eventState.SIGNIN;
  }

  function closeEvent (uint EventID) onlyOwners (msg.sender) public {
      events[EventID].state = eventState.CLOSED;
  }

  function rewardAttendees (uint EventID) onlyOwners (msg.sender) public {
      events[EventID].state = eventState.REWARDED;
      uint maxAttendees = events[EventID].maxAttendees;
      uint attendanceReward = events[EventID].rewardAmount;
      address[] storage attendees = events[EventID].presentMembers;
      uint i = 0;
      for (i; i < maxAttendees; i++) {
          address attendee = attendees[i];
          if (attendee == address(0)) {
              break;
          } else {
              _balances[attendee] = _balances[attendee].add(attendanceReward);
          }
      }
      _totalSupply.add((i + 1) * attendanceReward);

  }

  function createReward (string memory _description, uint _price, uint _maxClaimable) onlyOwners(msg.sender) public {
      numRewards ++;
      rewards[numRewards] = Reward({
          RewardID: numRewards,
          state: rewardState.BROWSE,
          description: _description,
          price: _price,
          numClaimed: 0,
          maxClaimable: _maxClaimable
      });


  }

  function allowRedemption (uint RewardID) onlyOwners(msg.sender) public {
      rewards[RewardID].state = rewardState.REDEEM;
  }

  function closeRedemption (uint RewardID) onlyOwners(msg.sender) public {
      rewards[RewardID].state = rewardState.CLOSED;
  }

  function claimReward (uint RewardID) public {
      require(rewards[RewardID].state == rewardState.REDEEM, "unable to redeem now");
      require(balanceOf(msg.sender) >= rewards[RewardID].price, "not enough Penn Tokens");
      require(rewards[RewardID].numClaimed < rewards[RewardID].maxClaimable, "this reward has been claimed too many times");
      _balances[msg.sender].sub(rewards[RewardID].price);
      _totalSupply.sub(rewards[RewardID].price);
      rewards[RewardID].numClaimed.add(1);
  }

  function addOwner (address newOwner) onlyOwners(msg.sender) public {
      owners[newOwner] = true;
  }

  function removeOwner (address owner) onlyOwners(msg.sender) public {
      owners[owner] = false;
  }



}
