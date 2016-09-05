#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <vector>
#include <chrono>

/*\Try to use m_Last as m_Parent for non-root Nodes, to use only
  2 uint32_t per node.
  - If m_Parent < it_n, it_n is a CHILD, and m_Parent is ACTUAL PARENT
  - Else if it_n < m_Parent, it_n is ROOT and m_Parent acts as m_Last
    - This includes m_Parent == m_Last == 0xFFFFFFFF (a ROOT with no children)
  An anonymous union m_Parent|m_Last is used according to these rules.

  list of ROOTS is embedded as a pred/succ list in elements, so that nodes
  require exactly 4xuint32_t (fits in a single 128B cache entry), and
  avoid foreach(n) CC search in EnumerateCC()

  \todo Try to SIMPLIFY Merge() code
*/
class MFSet_PC_NoRK_LL4u
{
public:
    MFSet_PC_NoRK_LL4u( uint32_t size ) { m_vecN.resize(size); Init(); }
    ~MFSet_PC_NoRK_LL4u() {}
    inline void Init()
        {
            for( uint32_t it_n=0; it_n<m_vecN.size(); it_n++ )
            {
                m_vecN[it_n].m_Next = 0xFFFFFFFF;
                m_vecN[it_n].m_Parent = 0xFFFFFFFF; //Root
                // root list
                m_vecN[it_n].m_Pred = it_n-1;
                m_vecN[it_n].m_Succ = it_n+1;
            }
            m_vecN.front().m_Pred = m_vecN.size()-1;
            m_vecN.back().m_Succ = 0;
        }
    inline uint32_t Find( uint32_t n )
        {
            if( m_vecN[n].m_Parent < n ) // non-root, maybe empty
            {
                m_vecN[n].m_Parent = Find( m_vecN[n].m_Parent );
                return m_vecN[n].m_Parent;
            }
            else //n < m_Parent
                return n; //BECAUSE m_vecN[n].m_Parent is LAST
        }

    /* Next-Last lists
       r1;
         r1 -> r1.n -> r1.nf ---> r1.l -> X
         |__________________________^
       r2;
         r2 -> r2.n -> r2.nf ---> r2.l -> X
         |__________________________^
       r1 + r2:
         r1 -> r1.n -> r1.nf -----> r1.l -> r2 -> r2.n -> .... -> r2.l -> X
         |_________________________________________________________^

       Merge( r1, r2 )
         r1.l.n = r2
         r1.l = r2.l
       For safety we should:
         r1.l.n = X
         r2.l = X
    */
    inline void Merge( uint32_t n1, uint32_t n2 )
        {
            uint32_t root1( Find(n1) );
            uint32_t root2( Find(n2) );

            // IMPORTANT: Using swap to avoid 2 large branches is
            // SLIGHTLY slower, but keeps code MUCH SHORTER, so we'll
            // do it by now

            // IMPORTANT: DO NOTHING IF ALREADY MERGED
            if( root1 == root2 ) return;
            else if( root2 < root1 ) std::swap(root1,root2);

            uint32_t last2( m_vecN[root2].m_Last );
            m_vecN[root2].m_Parent = root1;

            // Remove root2 from list of roots where root1 already is
            m_vecN[ m_vecN[root2].m_Succ ].m_Pred = m_vecN[root2].m_Pred;
            m_vecN[ m_vecN[root2].m_Pred ].m_Succ = m_vecN[root2].m_Succ;
            // TEMPORAL: Recommended for safety, but NOT REQUIRED
            // m_vecN[root2].m_Succ = 0xFFFFFFFF;
            // m_vecN[root2].m_Pred = 0xFFFFFFFF;

            //\todo THIS must be simpler, I'm sure...
            if( m_vecN[root1].m_Next != 0xFFFFFFFF ) //l1 not empty
            {
                m_vecN[ m_vecN[root1].m_Last ].m_Next = root2;
                if( m_vecN[root2].m_Next != 0xFFFFFFFF ) //l2 not empty
                    m_vecN[root1].m_Last = last2;
                else
                    m_vecN[root1].m_Last = root2;
            }
            else if( m_vecN[root2].m_Next != 0xFFFFFFFF ) //l2 not empty
            {
                m_vecN[ root1 ].m_Next = root2;
                m_vecN[ root1 ].m_Last = last2;
            }
            else // both empty
            {
                m_vecN[ root1 ].m_Next = root2;
                m_vecN[ root1 ].m_Last = root2;
            }

            /* TEMPORAL: this is for safety, but does not affect result...
            // l2.last becomes final \todo WE COULD REUSE its m_Last for list-length here
            if( last2 != 0xFFFFFFFF )
            {
            m_vecN[ last2 ].m_Next = 0xFFFFFFFF;
            m_vecN[ last2 ].m_Last = 0xFFFFFFFF;
            }
            // l2 becomes internal \todo WE COULD REUSE m_Last for list-length here
            ???m_vecN[root2].m_Last = 0xFFFFFFFF;
            */
        }
    inline uint32_t EnumerateCC( bool b_verbose )
        {
            if( b_verbose )
            {
                // Count and enumerate {S_i} \in S
                std::vector< std::vector<uint32_t> > vec_cc;
                {
                    auto start = std::chrono::system_clock::now();
                    const uint32_t first_root(0);
                    //\todo NO NEED, 0 WILL ALWAYS BE A ROOT because
                    //there's no other num smaller!!
                    // while( first_root > m_vecN[first_root].m_Parent ) first_root++;
                    uint32_t it_cc( first_root );
                    do
                    {
                        // create and fill CC
                        vec_cc.push_back( std::vector<uint32_t>() );
                        vec_cc.back().push_back( it_cc );
                        for( uint32_t it_ll=m_vecN[it_cc].m_Next;
                             it_ll != 0xFFFFFFFF;
                             it_ll = m_vecN[it_ll].m_Next )
                            vec_cc.back().push_back( it_ll );
                        // next root
                        it_cc = m_vecN[it_cc].m_Succ;
                    } while( it_cc != first_root );
                    auto end = std::chrono::system_clock::now();
                    std::chrono::duration<float> elapsed = end-start;
                    printf( "Enumerate CC = %d, in %f sec \n",
                            (int)vec_cc.size(), elapsed.count() );
                }
                // print
                for( uint32_t it_cc=0; it_cc<vec_cc.size(); it_cc++ )
                {
                    printf( "CC[%d] = %d [", it_cc, (int)vec_cc[it_cc].size() );
                    for( uint32_t it_nicc=0; it_nicc<vec_cc[it_cc].size(); it_nicc++ )
                        printf( " %d", vec_cc[it_cc][it_nicc] );
                    printf( " ]\n" );
                }
                return vec_cc.size();
            }
            else
            {
                // Count and enumerate {S_i} \in S
                uint32_t num_cc(0);
                uint32_t sum(0); //\todo To avoid elimiation of code with no side-effects
                auto start = std::chrono::system_clock::now();
                const uint32_t first_root(0);
                //\todo NO NEED, 0 WILL ALWAYS BE A ROOT because
                //there's no other num smaller!!
                // while( first_root > m_vecN[first_root].m_Parent ) first_root++;
                uint32_t it_cc( first_root );
                do
                {
                    // create and fill CC
                    for( uint32_t it_ll=m_vecN[it_cc].m_Next;
                         it_ll != 0xFFFFFFFF;
                         it_ll = m_vecN[it_ll].m_Next )
                        sum += it_ll;
                    // next root
                    it_cc = m_vecN[it_cc].m_Succ;
                    num_cc++;
                } while( it_cc != first_root );
                auto end = std::chrono::system_clock::now();
                std::chrono::duration<float> elapsed = end-start;
                printf( "Enumerate CC = %d, in %f sec \n",
                        num_cc, elapsed.count() );
                printf( "Sum =  %d\n", sum );
                return num_cc;
            }
        }
private:
    struct Entry
    {
        union { uint32_t m_Parent; uint32_t m_Last; };
        uint32_t m_Next;
        uint32_t m_Succ;
        uint32_t m_Pred;
    };
    std::vector<Entry> m_vecN;
};
