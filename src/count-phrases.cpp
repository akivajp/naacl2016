/////////////////////////////////////////////////////////////////////////////
///// @file        count-phrases.cpp
///// @brief       count frequence of phrases in given corpus
///// @date        25/08/2015 (created)
///// @date        29/09/2015 (last modified)
///// @author      Akiva Miura <akiva.miura@gmail.com>
///// @par Copyright: (C) 2015 Akiva Miura
///// @par Licence:   MIT License http://opensource.org/licenses/MIT
///////////////////////////////////////////////////////////////////////////////

#include "esa.hxx"
#include <fstream>
#include <iostream>
#include <map>
#include <vector>
#include <sstream>
#include <stdio.h>

using namespace std;

vector<string> split(const string& str, const string& delim = " ")
{
  vector<string> v;
  size_t current = 0, found;
  while ((found = str.find(delim, current)) != string::npos) {
    string word = string(str, current, found - current);
    v.push_back(word);
    current = found + delim.size();
  }
  v.push_back(string(str, current, str.size() - current));
  return v;
}

class SuffixFinder
{
  public:
    SuffixFinder()
      : T(), SA(), L(), R(), D(), word2id(), id2word(), nodeNum(0)
    { }

    bool build()
    {
      int n = T.size();
      int alphaSize = word2id.size();
      SA.resize(n);
      L.resize(n);
      R.resize(n);
      D.resize(n);
      if (esaxx(T.begin(), SA.begin(),
                L.begin(), R.begin(),  D.begin(),
                n, alphaSize, nodeNum) == -1){
          return false;
      }
      return true;
    }

    int countPhrase(const vector<string> &phrase, int left = 0, int right = -1, int index = 0)
    {
      if (left < 0) {
        return 0;
      }
      if (right < 0) {
        right = T.size() - 1;
      }
      if (index >= phrase.size())
      {
//cout << "left:" << left << " right:" << right << endl;
        return right - left + 1;
      }
      int wordLeft = findWordLeft(phrase, left, right, index);
//cout << "wordLeft: " << wordLeft << endl;
      int wordRight = findWordRight(phrase, left, right, index);
//cout << "wordRight: " << wordRight << endl;
      return countPhrase(phrase, wordLeft, wordRight, index + 1);
    }

    int countPhrase(const string &phrase)
    {
      vector<string> words = split(phrase);
      return countPhrase(words);
    }

    int findWordLeft(const vector<string> &phrase, int left = 0, int right = -1, int index = 0)
    {
      if (right < 0) {
        right = T.size() - 1;
      }
      int id = getID(phrase[index]);
      int mid = -1;
      int midID = -1;
      while (left < right) {
        mid = (left + right) / 2;
        midID = T[SA[mid]+index];
//cout << "left:" << left << " right:" << right << " mid:" << mid << " id:" << id << " midID:" << midID << endl;
        if (id <= midID) {
          right = mid - 1;
        } else if (id > midID) {
          left = mid + 1;
        }
      }
      mid = (left + right) / 2;
      if (id == T[SA[mid]+index]) {
        return mid;
      } else if (id == T[SA[mid + 1]+index]) {
        return mid + 1;
      } else {
        return -1;
      }
    }

    int findWordRight(const vector<string> &phrase, int left = 0, int right = -1, int index = 0)
    {
      if (right < 0) {
        right = T.size() - 1;
      }
      int id = getID(phrase[index]);
      int mid = -1;
      int midID = -1;
      while (left < right)
      {
        mid = (left + right) / 2;
//cout << "left:" << left << " right:" << right << " mid:" << mid << " id:" << id << " midID:" << midID << endl;
        midID = T[SA[mid]+index];
        if (id < midID) {
          right = mid - 1;
        } else if (id >= midID) {
          left = mid + 1;
        }
      }
      mid = (left + right) / 2;
      if (id == T[SA[mid]+index]) {
        return mid;
      } else if (id == T[SA[mid - 1]+index]) {
        return mid - 1;
      } else {
        return -1;
      }
    }

    bool enumMaximalSubStrings()
    {
      // BWT の変化を記録
      int size = T.size();
      vector<int> rank(size);
      int r = 0;
      for (int i = 0; i < size; i++)
      {
        if (i == 0 || T[(SA[i] + size - 1) % size] != T[(SA[i - 1] + size - 1) % size]) {
            r++;
        }
        rank[i] = r;
      }
      // 極大部分文字列を列挙
      stringstream bufSubString;
      for (int i = 0; i < nodeNum; ++i)
      {
        int len = D[i];
        if (len == 0 || (rank[R[i] - 1] - rank[L[i]] == 0)) {
            continue;
        }
        int freq = R[i] - L[i];
        int begin = SA[L[i]];
        for (int j = 0; j < len; ++j)
        {
          const string &word = id2word[ T[begin + j] ];
//          if ( word == "<BR>" )
//          {
//            if ( ! bufSubString.str().empty() )
//            {
//              cout << bufSubString.str();
//              bufSubString.str("");
//              cout << "\t" << freq;
//              cout << endl;
//            }
//          }
//          else
          {
            if ( ! bufSubString.str().empty() )
            {
              bufSubString << " ";
            }
            bufSubString << word;
          }
//          cout << bufSubString.str();
        }
        if ( ! bufSubString.str().empty() )
        {
          cout << bufSubString.str();
          bufSubString.str("");
          cout << "\t" << freq;
          cout << endl;
        }
      }
    }

    bool enumSubStrings()
    {
      cout << "Num\tSA\tSubString" << endl;
      for (int i = 0; i < T.size(); i++)
      {
//        string word = id2word[ T[SA[i]] ];
        cout << i << "\t" << SA[i] << "\t";
        cout << getSubString(SA[i]) << endl;
      }
      return true;
    }

    bool enumTreeNodes()
    {
      cout << "L\tT\tR-L\tD\tNodeString" << endl;
      for (int i = 0; i < nodeNum; i++)
      {
        cout << L[i] << "\t" << R[i] << "\t" << R[i] - L[i] << "\t" << D[i] << "\t";
        int beg = SA[L[i]];
        int len = D[i];
        for (int j = 0; j < len; j++) {
          cout << id2word[ T[beg + j] ] << " ";
        }
        cout << endl;
      }
    }

    string getSubString(int start = 0, int maxlen=10)
    {
      string subst;
      int len = T.size() - start;
      if (len > maxlen) {
        len = maxlen;
      }
      for (int i = start; i < start + len; i++)
      {
        subst += id2word[T[i]] + " ";
      }
      if (T.size() - start > maxlen)
      {
        subst += " ...";
      }
      return subst;
    }

    bool loadFromStandardInput()
    {
      istreambuf_iterator<char> isit(cin);
      istreambuf_iterator<char> end;
      string word;
      while (isit != end){
        char c = *isit++;
        if (!isspace(c)){
          word += c;
        } else if (word.size() > 0){
          T.push_back(getID(word));
          word = "";
          if (c == '\n')
          {
            T.push_back(getID("<BR>"));
          }
        }
      }
      if (word.size() > 0){
        T.push_back(getID(word));
      }

      return true;
    }

    int getID(const string &word)
    {
      map<string,int>::const_iterator found = word2id.find(word);
      if (found == word2id.end()) {
        int newID = (int)id2word.size();
        word2id[word] = newID;
        id2word.push_back(word);
        return newID;
      } else {
        return found->second;
      }
    }

    vector<int> T;  // array
    vector<int> SA; // suffix array
    vector<int> L;  // left boundaries of internal node
    vector<int> R;  // right boundaries of internal node
    vector<int> D;  // depths of internal node
    map<string,int> word2id;
    vector<string> id2word;
    int nodeNum;
};

int usage(int argc, char *argv[])
{
  printf("usage 1: %s path_to_phrases < path_to_corpus > path_to_stats\n", argv[0]);
  printf("usage 2: %s --maxsubst < path_to_corpus > path_to_stats\n", argv[0]);
  return -1;
}

int countPhrases(const string &filePhrases) {
  ifstream ifs(filePhrases.c_str());
  if (ifs.fail())
  {
    std::cerr << "file not found: " << filePhrases << endl;
    return -1;
  }

  SuffixFinder finder;
  finder.loadFromStandardInput();
  if (! finder.build()) {
      return -1;
  }

  string line;
  while (getline(ifs, line))
  {
    if (! line.empty())
    {
      cout << line << "\t";
      cout << finder.countPhrase(line);
      cout << endl;
    }
  }
  return 0;
}

int enumSubPhrases()
{
  SuffixFinder finder;
  finder.loadFromStandardInput();
  if (! finder.build()) {
    return -1;
  }
  finder.enumMaximalSubStrings();
  return 0;
}

int main(int argc, char *argv[])
{
  string strPhrases;
  if ( argc < 2 )
  {
    return usage(argc, argv);
  }
  string arg1 = argv[1];
  if (arg1[0] == '-')
  {
    if (arg1 == "--maxsubst")
    {
      return enumSubPhrases();
    }
    else
    {
      std::cerr << "unknown option: " << arg1 << endl;
      return -1;
    }
  } else {
    return countPhrases(arg1);
  }
}

